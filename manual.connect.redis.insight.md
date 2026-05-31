# RedisInsight \xe2\x86\x92 DragonFly Connection

## Connection URL

```
redis://admin:YOUR_PASSWORD@dragonfly:6379
```

> Replace `YOUR_PASSWORD` with the password from `dragonfly_data/acl.conf`

---

## Steps

1. Open RedisInsight in browser
2. Click **Add database**
3. Paste the URL above into **Connection URL**
4. Click **Test connection** \xe2\x86\x92 should show OK
5. Click **Add database**

---

## Find your password

```bash
cat ~/Astro-Hono-oRpc/docker/dragonfly/dragonfly_data/acl.conf
# looks like: user admin on >YOUR_PASSWORD
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Connection refused | Make sure RedisInsight is on the `internal` Docker network |
| Auth failed | Double-check password from `acl.conf` |
| default user rejected | Use `admin` user, not `default` |

---

> Warning: Do NOT use `127.0.0.1` - DragonFly has no exposed ports to the host.
> Use the container name `dragonfly` instead.
