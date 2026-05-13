# mTLS Setup Manual
> Mutual TLS setup for NPMplus + Dragonfly (Redis) on fast-web-tech.co.uk

---

## Architecture

```
Internet
    ↓
VPS Firewall (IP whitelist - home IP only)
    ↓
mTLS (client cert required - homepc.p12)
    ↓
NPMplus
    ↓
Internal Services (docker_internal network)
```

---

## Server Setup

### Step 1 — Create CA Directory Structure

```bash
mkdir -p ~/ca/{certs,crl,newcerts}
echo 1000 > ~/ca/serial
echo 1000 > ~/ca/crlnumber
touch ~/ca/index.txt
```

### Step 2 — Create `~/ca/openssl.cnf`

```bash
cat > ~/ca/openssl.cnf << 'EOF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = /home/igor/ca
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
crlnumber         = $dir/crlnumber
crl               = $dir/crl/ca.crl
private_key       = $dir/ca.key
certificate       = $dir/ca.crt
default_crl_days  = 30
default_md        = sha256
policy            = policy_strict

[ policy_strict ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ crl_ext ]
authorityKeyIdentifier = keyid:always

[ usr_cert ]
basicConstraints       = CA:FALSE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
EOF
```

### Step 3 — Generate CA Key and Certificate

```bash
cd ~/ca

# Generate CA key (remember the password!)
openssl genrsa -aes256 -out ca.key 4096

# Generate CA certificate
openssl req -new -x509 -days 1826 -key ca.key -out ca.crt -subj "/CN=HomeCA"

# Generate initial empty CRL
openssl ca -config openssl.cnf -gencrl -out crl/ca.crl
```

> **Important**: The CA password is required every time you sign or revoke a cert. Store it in a password manager.

### Step 4 — Generate Client Certificate for Home PC

```bash
cd ~/ca

# Generate client key
openssl genrsa -out certs/homepc.key 4096

# Generate certificate signing request
openssl req -new -key certs/homepc.key -out certs/homepc.csr -subj "/CN=homepc"

# Sign with CA (will ask for CA password)
openssl ca -config openssl.cnf -extensions usr_cert -days 1826 -in certs/homepc.csr -out certs/homepc.crt

# Bundle into p12 for browser import (set an export password!)
openssl pkcs12 -export \
  -out certs/homepc.p12 \
  -inkey certs/homepc.key \
  -in certs/homepc.crt \
  -certfile ca.crt
```

### Step 5 — Generate Client Certificate for Mobile

> Each device gets its own cert so it can be revoked independently.

```bash
cd ~/ca

# Generate mobile key and cert
openssl genrsa -out certs/mobile.key 4096
openssl req -new -key certs/mobile.key -out certs/mobile.csr -subj "/CN=mobile"
openssl ca -config openssl.cnf -extensions usr_cert -days 1826 -in certs/mobile.csr -out certs/mobile.crt

# Bundle for mobile import
openssl pkcs12 -export \
  -out certs/mobile.p12 \
  -inkey certs/mobile.key \
  -in certs/mobile.crt \
  -certfile ca.crt
```

### Step 6 — Copy CA Cert to NPMplus

```bash
sudo mkdir -p ~/Astro-Hono-oRpc/docker/npm_plus/npm_plus_data/tls/client-ca
sudo cp ~/ca/ca.crt ~/Astro-Hono-oRpc/docker/npm_plus/npm_plus_data/tls/client-ca/
sudo cp ~/ca/crl/ca.crl ~/Astro-Hono-oRpc/docker/npm_plus/npm_plus_data/tls/client-ca/
```

---

## Home PC Setup

### Step 7 — Download Certs to Home PC

```bash
scp ionos-igor:~/ca/certs/homepc.p12 ~/Downloads/
scp ionos-igor:~/ca/certs/homepc.key ~/Downloads/
scp ionos-igor:~/ca/ca.crt ~/Downloads/
```

### Step 8 — Move to Secure Location

```bash
mkdir -p ~/.certs
mv ~/Downloads/homepc.p12 ~/.certs/
mv ~/Downloads/homepc.key ~/.certs/
mv ~/Downloads/ca.crt ~/.certs/

# Secure permissions
chmod 600 ~/.certs/homepc.key
chmod 644 ~/.certs/ca.crt

# Extract cert from p12
openssl pkcs12 -in ~/.certs/homepc.p12 -clcerts -nokeys -out ~/.certs/homepc.crt
chmod 644 ~/.certs/homepc.crt
```

### Step 9 — Import p12 into Browser

**Chrome:**
```
Settings → Privacy & Security → Security → Manage Certificates → Import → homepc.p12
```

**Firefox:**
```
Settings → Privacy & Security → View Certificates → Your Certificates → Import → homepc.p12
```

---

## Mobile Setup

### Step 10 — Download mobile.p12 to Home PC

```bash
scp ionos-igor:~/ca/certs/mobile.p12 ~/Downloads/
```

### Step 11 — Transfer and Install on Mobile

**iOS — AirDrop:**
```
AirDrop mobile.p12 to iPhone
→ Settings → Profile Downloaded → Install
→ Settings → General → VPN & Device Management → install profile
→ Settings → About → Certificate Trust Settings → enable HomeCA
```

**Android:**
```
Transfer mobile.p12 via cable or email
→ Settings → Security → Install Certificate → CA Certificate
→ Select mobile.p12 → enter export password
```

---

## NPMplus UI Setup

### Step 12 — Upload CA as mTLS Certificate

- Go to **Certificates** → **Add Certificate** → **mTLS**
- Upload `ca.crt`
- Name it `HomeCA`
- Save

### Step 13 — Enable mTLS on Each Proxy Host

For every host you want to protect:
- Edit proxy host → **TLS** tab
- **mTLS Certificate** → select `HomeCA`
- **Make mTLS Optional** → off
- Save

Protected hosts:
- `arcane.fast-web-tech.co.uk` ✓
- `npm.fast-web-tech.co.uk` ✓
- `goaccess.fast-web-tech.co.uk` ✓

### Step 14 — Enable mTLS on Redis Stream

- Edit stream (port 6380) → **Details** tab
- **TLS to upstream** → OFF (Dragonfly is plain TCP internally)
- **TLS** tab → **TLS Certificate** → select `fast-web-tech.co.uk`
- **mTLS Certificate** → select `HomeCA`
- **Make mTLS Optional** → off
- Save

---

## ioredis Client Configuration

```bash
# Extract cert from p12 on home PC
openssl pkcs12 -in ~/.certs/homepc.p12 -clcerts -nokeys -out ~/.certs/homepc.crt
```

**.env:**
```env
VPS_REDIS_URL=rediss://appuser:password@fast-web-tech.co.uk:6380
VPS_TLS_SERVER=fast-web-tech.co.uk
VPS_CA_CERT=/home/youruser/.certs/ca.crt
VPS_CLIENT_CERT=/home/youruser/.certs/homepc.crt
VPS_CLIENT_KEY=/home/youruser/.certs/homepc.key
```

**TypeScript (Node.js fs):**
```typescript
import Redis from 'ioredis';
import { readFileSync } from 'fs';

const redis = new Redis(process.env.VPS_REDIS_URL, {
  enableReadyCheck: false,
  tls: {
    servername: process.env.VPS_TLS_SERVER,
    ca: readFileSync(process.env.VPS_CA_CERT!),
    cert: readFileSync(process.env.VPS_CLIENT_CERT!),
    key: readFileSync(process.env.VPS_CLIENT_KEY!),
    rejectUnauthorized: true,
  },
  maxRetriesPerRequest: 3,
  retryStrategy: (times) => {
    if (times > 3) return null;
    return Math.min(times * 200, 1000);
  },
  lazyConnect: true,
});
```

**TypeScript (Bun native):**
```typescript
import Redis from 'ioredis';

const redis = new Redis(process.env.VPS_REDIS_URL, {
  enableReadyCheck: false,
  tls: {
    servername: process.env.VPS_TLS_SERVER,
    ca: await Bun.file(process.env.VPS_CA_CERT!).text(),
    cert: await Bun.file(process.env.VPS_CLIENT_CERT!).text(),
    key: await Bun.file(process.env.VPS_CLIENT_KEY!).text(),
    rejectUnauthorized: true,
  },
  maxRetriesPerRequest: 3,
  retryStrategy: (times) => {
    if (times > 3) return null;
    return Math.min(times * 200, 1000);
  },
  lazyConnect: true,
});
```

---

## CRL Auto-Renewal (Cron Job)

CRL expires every 30 days. Cron runs on the 1st of every month at midnight.

### Step 15 — Create CA Password File

```bash
echo "your-ca-password" > /home/igor/ca/.ca-password
chmod 400 /home/igor/ca/.ca-password
```

> Replace `your-ca-password` with your actual CA password.

### Step 16 — Allow Passwordless sudo for Cron

```bash
sudo visudo
```

Add at the bottom:
```
igor ALL=(ALL) NOPASSWD: /bin/cp /home/igor/ca/crl/ca.crl /home/igor/Astro-Hono-oRpc/docker/npm_plus/npm_plus_data/tls/client-ca/ca.crl
igor ALL=(ALL) NOPASSWD: /usr/bin/docker restart npmplus
```

### Step 17 — Add Cron Job

```bash
crontab -e
```

Add:
```bash
0 0 1 * * cd /home/igor/ca && openssl ca -config openssl.cnf -gencrl -passin file:/home/igor/ca/.ca-password -out crl/ca.crl && sudo cp crl/ca.crl /home/igor/Astro-Hono-oRpc/docker/npm_plus/npm_plus_data/tls/client-ca/ca.crl && sudo docker restart npmplus
```

### Test Cron Job Manually

```bash
cd /home/igor/ca && openssl ca -config openssl.cnf -gencrl -passin file:/home/igor/ca/.ca-password -out crl/ca.crl && sudo cp crl/ca.crl /home/igor/Astro-Hono-oRpc/docker/npm_plus/npm_plus_data/tls/client-ca/ca.crl && sudo docker restart npmplus
```

Expected output:
```
Using configuration from openssl.cnf
npmplus
```

---

## If Device is Compromised

### PC Compromised

```bash
cd ~/ca

# 1. Revoke cert
openssl ca -config openssl.cnf -revoke certs/homepc.crt

# 2. Regenerate CRL immediately
openssl ca -config openssl.cnf -gencrl -passin file:/home/igor/ca/.ca-password -out crl/ca.crl

# 3. Copy to NPMplus
sudo cp crl/ca.crl ~/Astro-Hono-oRpc/docker/npm_plus/npm_plus_data/tls/client-ca/ca.crl

# 4. Restart NPMplus
sudo docker restart npmplus

# 5. Issue new cert for replacement PC
openssl genrsa -out certs/newpc.key 4096
openssl req -new -key certs/newpc.key -out certs/newpc.csr -subj "/CN=newpc"
openssl ca -config openssl.cnf -extensions usr_cert -days 1826 -in certs/newpc.csr -out certs/newpc.crt
openssl pkcs12 -export \
  -out certs/newpc.p12 \
  -inkey certs/newpc.key \
  -in certs/newpc.crt \
  -certfile ca.crt
```

### Mobile Compromised

```bash
cd ~/ca

# 1. Revoke mobile cert only — PC cert unaffected
openssl ca -config openssl.cnf -revoke certs/mobile.crt

# 2. Regenerate CRL
openssl ca -config openssl.cnf -gencrl -passin file:/home/igor/ca/.ca-password -out crl/ca.crl

# 3. Copy to NPMplus
sudo cp crl/ca.crl ~/Astro-Hono-oRpc/docker/npm_plus/npm_plus_data/tls/client-ca/ca.crl

# 4. Restart NPMplus
sudo docker restart npmplus

# 5. Issue new cert for replacement mobile
openssl genrsa -out certs/mobile2.key 4096
openssl req -new -key certs/mobile2.key -out certs/mobile2.csr -subj "/CN=mobile2"
openssl ca -config openssl.cnf -extensions usr_cert -days 1826 -in certs/mobile2.csr -out certs/mobile2.crt
openssl pkcs12 -export \
  -out certs/mobile2.p12 \
  -inkey certs/mobile2.key \
  -in certs/mobile2.crt \
  -certfile ca.crt
```

---

## File Structure

```
~/ca/                                        # Server - CA files
├── openssl.cnf                              # CA config
├── ca.key                                   # CA private key — NEVER share! (chmod 400)
├── ca.crt                                   # CA certificate
├── .ca-password                             # CA password for cron (chmod 400)
├── serial                                   # cert serial counter
├── crlnumber                                # CRL serial counter
├── index.txt                                # cert database
├── certs/
│   ├── homepc.key                           # home PC private key
│   ├── homepc.crt                           # home PC certificate
│   ├── homepc.p12                           # home PC browser bundle
│   ├── mobile.key                           # mobile private key
│   ├── mobile.crt                           # mobile certificate
│   └── mobile.p12                           # mobile install bundle
├── crl/
│   └── ca.crl                               # certificate revocation list
└── newcerts/                                # auto-generated signed certs

~/.certs/                                    # Home PC - client certs
├── ca.crt                                   # CA certificate
├── homepc.p12                               # browser bundle
├── homepc.key                               # client private key
└── homepc.crt                               # client certificate
```

---

## Security Layers

| Layer | Protection |
|-------|-----------|
| VPS Firewall | IP whitelist - home IP only |
| mTLS | Client cert required - 4096-bit RSA |
| CRL | Per-device revocation within hours |
| ACL | Redis password + user permissions |
| Docker network | Services isolated on docker_internal |
| TLS to upstream | Off — Dragonfly stays plain TCP internally |
