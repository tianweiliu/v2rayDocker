#!/bin/bash
# FILE="Caddy"
domain="$1"
psname="$2"
sendThrough="0.0.0.0"
port="2333"
path="/one"
certPath="/root/.caddy/acme/acme-v02.api.letsencrypt.org/sites"
uuid="51be9a06-299f-43b9-b713-1ec5eb76e3d7"
if [ "$3" ]; then
  sendThrough="$3"
fi
if [ !"$4" ]; then
  uuid=$(uuidgen)
  echo "uuid 将会系统随机生成"
else
  uuid="$4"
fi
cat >/etc/Caddyfile <<EOF
$domain {
  log ./caddy.log
  proxy /one https://localhost:$port {
    insecure_skip_verify
    header_upstream X-Forwarded-Proto "https"
    header_upstream Host "$domain"
  }
}

EOF

# v2ray
cat >/etc/v2ray/config.json <<EOF
{
  "inbounds": [
    {
      "port": $port,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 64
          }
        ]
      },
      "streamSettings": {
        "network": "h2",
        "security": "tls",
        "httpSettings": {
          "host": ["$domain"],
          "path": "$path"
        },
        "tlsSettings": {
          "serverName": "$domain",
          "certificates": [
            {
              "certificateFile": "$certPath/$domain/$domain.crt",
              "keyFile": "$certPath/$domain/$domain.key"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "sendThrough": "$sendThrough",
      "protocol": "freedom",
      "settings": {}
    }
  ]
}

EOF

cat >/srv/sebs.json <<EOF
{
  "add":"$domain",
  "aid":"0",
  "host":"",
  "id":"$uuid",
  "net":"h2",
  "path":"$path",
  "port":"443",
  "ps":"$psname",
  "tls":"tls",
  "type":"none",
  "v":"2"
}

EOF

pwd
cp /etc/Caddyfile .
nohup /bin/parent caddy --log stdout --agree=false &
echo "配置 JSON 详情"
echo " "
cat /etc/v2ray/config.json
echo " "
node v2ray.js
sleep 3
/usr/bin/v2ray -config /etc/v2ray/config.json
