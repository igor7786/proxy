 ssh ionos-igor 'cd Astro-Hono-oRpc/docker && docker compose down'
 docker exec crowdsec cscli decisions delete --ip 31.94.36.187
 docker exec crowdsec cscli decisions list
cat > conf/parsers/s02-enrich/my-whitelist.yaml << 'EOF'
name: crowdsecurity/my-whitelist
description: Whitelist home IPs
whitelist:
  reason: "home IP - Igor"
  ip:
    - "148.252.144.139"
    - "31.94.36.187"
EOF
