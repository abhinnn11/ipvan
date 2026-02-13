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
# ---- Fix old IPVanish configs for OpenVPN 2.6 ----

# remove deprecated directives
sed -i '/keysize/d' "$SERVER"
sed -i '/comp-lzo/d' "$SERVER"
sed -i '/reneg-sec/d' "$SERVER"

# replace cipher (old BF-CBC removed from OpenVPN 2.6 default)
sed -i 's/cipher AES-256-CBC/data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC/g' "$SERVER"
sed -i '/auth SHA256/d' "$SERVER"

# ensure auth file
sed -i 's/auth-user-pass/auth-user-pass \/config\/auth.txt/g' "$SERVER"

# ensure proper routing
grep -q "redirect-gateway" "$SERVER" || echo "redirect-gateway def1" >> "$SERVER"

# allow modern negotiation
echo "allow-compression no" >> "$SERVER"
echo "auth-nocache" >> "$SERVER"
echo "verb 3" >> "$SERVER"

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
