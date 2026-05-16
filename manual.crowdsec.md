# CrowdSec firewall bouncer — quick reference

## Check status & logs

```bash
sudo systemctl status crowdsec-firewall-bouncer
sudo journalctl -u crowdsec-firewall-bouncer -n 50 --no-pager
```

## Re-register the bouncer (after delete or API key loss)

```bash
# 1. Generate a new key inside the CrowdSec container
docker compose exec crowdsec cscli bouncers add crowdsec-firewall-bouncer

# 2. Paste the key into the config
sudo nano /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
# set: api_key: <new-key>

# 3. Restart the bouncer
sudo systemctl restart crowdsec-firewall-bouncer

# 4. Confirm it re-appeared
docker compose exec crowdsec cscli bouncers list
```

## Verify nftables rules are active

```bash
sudo nft list ruleset | grep crowdsec
```

You should see `crowdsec-chain-input` and `crowdsec-chain-forward` with DROP rules.

---

## Fresh install — nftables mode (Ubuntu, CrowdSec in Docker)

### 1. Add the CrowdSec repository and install the bouncer

```bash
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
sudo apt install crowdsec-firewall-bouncer-nftables -y
```

> Use `crowdsec-firewall-bouncer-nftables` — this pulls the nftables variant.
> The plain `crowdsec-firewall-bouncer` package defaults to iptables.

### 2. Generate an API key inside your CrowdSec container

```bash
docker compose exec crowdsec cscli bouncers add crowdsec-firewall-bouncer
# Copy the printed key
```

### 3. Configure the bouncer

```bash
sudo nano /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
```

Minimum settings for Docker + nftables:

```yaml
mode: nftables
api_url: http://127.0.0.1:8080/   # port-mapped from container
api_key: <key from step 2>

nftables:
  ipv4:
    enabled: true
    set-only: false
    table: crowdsec
    chain: crowdsec-chain
    priority: -10
  ipv6:
    enabled: true
    set-only: false
    table: crowdsec6
    chain: crowdsec6-chain
    priority: -10

nftables_hooks:
  - input
  - forward
```

### 4. Enable and start

```bash
sudo systemctl enable crowdsec-firewall-bouncer
sudo systemctl start crowdsec-firewall-bouncer
sudo systemctl status crowdsec-firewall-bouncer
```

### 5. Verify

```bash
docker compose exec crowdsec cscli bouncers list
sudo nft list ruleset | grep crowdsec
```

---

## iptables mode (alternative)

If you prefer iptables instead of nftables:

```bash
sudo apt install crowdsec-firewall-bouncer -y
```

Then in the config set:

```yaml
mode: iptables
iptables_chains:
  - INPUT
  - FORWARD
  - DOCKER-USER
```

The `DOCKER-USER` chain is important — it ensures blocked IPs are also dropped for traffic routed through Docker.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `bouncer stream halted` in logs | API key invalid or CrowdSec unreachable | Re-register bouncer, check `api_url` |
| Two entries in `bouncers list` | Bouncer registered on two Docker networks | Delete the stale entry with `cscli bouncers delete <name>` |
| No crowdsec chains in `nft list ruleset` | Bouncer not running or wrong mode | Check `systemctl status`, verify `mode: nftables` in config |
| Bouncer active but `Inactive` shown in app | Stale registration from old IP | Delete old entry, restart bouncer to re-register |
