#!/bin/bash
set -e

echo "Starting IPVanish..."

# create auth file
cat <<EOF > /config/auth.txt
$USERNAME
$PASSWORD
EOF

chmod 600 /config/auth.txt

# choose server
if [ "$RANDOMIZE" = "true" ]; then
    SERVER=$(ls /config/*.ovpn | grep "$COUNTRY" | shuf -n1)
else
    SERVER=$(ls /config/*.ovpn | grep "$COUNTRY" | head -n1)
fi

echo "Using server: $SERVER"

# fix ovpn options
sed -i 's/auth-user-pass/auth-user-pass \/config\/auth.txt/g' "$SERVER"
echo "script-security 2" >> "$SERVER"
echo "redirect-gateway def1" >> "$SERVER"

# enable routing
sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true

# start tinyproxy
tinyproxy

# start vpn
exec openvpn --config "$SERVER" --verb 3
