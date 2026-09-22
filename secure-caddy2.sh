#!/bin/bash
set -e
CADDYFILE=/etc/caddy/Caddyfile

# Reuse hash from env file
HASH=$(grep '^AQ_DASH_PASS=' /opt/aq-app/infra/.env | sed 's/^AQ_DASH_PASS=//' | head -1)
# Get the bcrypt hash directly (the previous $HASH value)
BCRYPT='$2a$14$H9.PfsGHbqB8zPQn5rRa.eLQNnyEF7vRoLTGqMqP93uDqW/xAK6u6'

cat > $CADDYFILE <<EOF
# Caddy reverse proxy pour VPS3 edge
# - TLS automatique (Let's Encrypt)
# - HTTP/3 + Brotli activés par défaut
# - Basic auth sur edge.astroquest.fr (credentials in /opt/aq-app/infra/.env)

edge.astroquest.fr {
    basicauth {
        astroquest ${BCRYPT}
    }

    encode zstd gzip

    # === SoaringEVO — backend OGN temps reel (WebSocket + API) ===
    handle /soaring/packs/* {
        uri strip_prefix /soaring/packs
        root * /opt/evo-server/packs
        file_server
    }

    handle /soaring/* {
        uri strip_prefix /soaring
        reverse_proxy 127.0.0.1:9411
    }

    # === AstroQuest WebSocket backend ===
    @aq_ws path /ws /ws/*
    handle @aq_ws {
        reverse_proxy 127.0.0.1:8787 {
            header_up +Connection
            header_up +Upgrade
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            transport http {
                read_timeout  3600s
            }
        }
    }

    # === AstroQuest REST API ===
    handle_path /aq-api/* {
        reverse_proxy 127.0.0.1:8787 {
            transport http {
                read_timeout 5s
            }
        }
    }

    handle_path /aq-api {
        reverse_proxy 127.0.0.1:8787/api/health {
            transport http {
                read_timeout 5s
            }
        }
    }

    # === AstroQuest LiteLLM API (OpenAI-compatible) ===
    @litellm path /litellm/*
    handle @litellm {
        uri strip_prefix /litellm
        reverse_proxy 127.0.0.1:4000 {
            header_up Host {host}
            header_up X-Real-IP {remote_host}
            transport http {
                response_header_timeout 60s
                read_timeout 60s
            }
        }
    }

    # === Health check (legacy Bun) ===
    @health path /health
    handle @health {
        reverse_proxy localhost:3000
    }

    # === AstroQuest Frontend — SPA fallback DOIT etre AVANT le catch-all ===
    @aq_fe_spa path /dev/* /playground/* /ceo/* /projects/* /not-a-real-file-*
    handle @aq_fe_spa {
        root * /var/www/aq
        rewrite * /index.html
        file_server
    }

    # === AstroQuest Frontend (static files - catch-all) ===
    @aq_fe not path /litellm/* /aq-api* /ws* /ws /soaring* /health /dev/* /playground/* /ceo/* /projects/* /not-a-real-file-*
    handle @aq_fe {
        root * /var/www/aq
        file_server
    }

    # === Catch-all legacy Bun ===
    reverse_proxy 127.0.0.1:3000 {
        header_up Host {host}
        header_up X-Real-IP {remote_host}
        transport http {
            response_header_timeout 30s
            read_timeout 30s
        }
    }

    log {
        format json
    }
}
EOF

echo "[1] Caddyfile rewritten with basicauth"
echo "[2] Validating..."
caddy validate --config $CADDYFILE 2>&1 | tail -3
echo "[3] Reloading..."
caddy reload --config $CADDYFILE 2>&1
sleep 3

echo ""
echo "=== TEST WITHOUT (should be 401) ==="
curl -s -o /dev/null -w 'HTTP=%{http_code}\\n' https://edge.astroquest.fr/
echo "=== TEST WITH WRONG PASS ==="
curl -s -o /dev/null -w 'HTTP=%{http_code}\\n' -u 'astroquest:wrong' https://edge.astroquest.fr/
echo "=== TEST WITH RIGHT PASS ==="
curl -s -o /dev/null -w 'HTTP=%{http_code}\\n' -u 'astroquest:XVFZXhGwNTYKK6oks8pX' https://edge.astroquest.fr/

echo ""
echo "================================================="
echo "  AUTH ACTIVE"
echo "  User: astroquest"
echo "  Pass: XVFZXhGwNTYKK6oks8pX"
echo "================================================="