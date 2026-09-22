#!/bin/bash
set -e
CADDYFILE=/etc/caddy/Caddyfile
cp "$CADDYFILE" "${CADDYFILE}.bak2"

cat > "$CADDYFILE" <<'EOF'
# Caddy reverse proxy pour VPS3 edge
# - TLS automatique (Let's Encrypt)
# - HTTP/3 + Brotli activés par défaut

edge.astroquest.fr {
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
                read_timeout 3600s
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
    # Matche les routes SPA qui doivent renvoyer index.html (React Router)
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

echo "=== Validate ==="
caddy validate --config "$CADDYFILE" 2>&1
echo "=== Format ==="
caddy fmt --overwrite "$CADDYFILE" 2>&1
echo "=== Reload ==="
caddy reload --config "$CADDYFILE" 2>&1
sleep 3
echo "=== TEST /dev/playground ==="
curl -sI https://edge.astroquest.fr/dev/playground | head -5
echo "=== TEST /ceo/test ==="
curl -sI https://edge.astroquest.fr/ceo/test | head -5
echo "=== TEST / ==="
curl -sI https://edge.astroquest.fr/ | head -5
echo "=== TEST /assets/home-DUhiI47c.js ==="
curl -sI https://edge.astroquest.fr/assets/home-DUhiI47c.js | head -5