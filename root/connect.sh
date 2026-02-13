#!/bin/bash
set -eo pipefail

echo "Starting IPVanish..."

########################
# create auth file
########################
cat <<EOF > /config/auth.txt
$USERNAME
$PASSWORD
EOF
chmod 600 /config/auth.txt

########################
# choose server
########################
if [ "$RANDOMIZE" = "true" ]; then
    SERVER=$(find /config -name "*.ovpn" | grep "$COUNTRY" | shuf -n1)
else
    SERVER=$(find /config -name "*.ovpn" | grep "$COUNTRY" | head -n1)
fi

echo "Using server: $SERVER"

########################
# sanitize IPVanish config for OpenVPN 2.6
########################

# remove deprecated/unsafe options
sed -i '/keysize/d' "$SERVER"
sed -i '/comp-lzo/d' "$SERVER"
sed -i '/reneg-sec/d' "$SERVER"
sed -i '/auth SHA256/d' "$SERVER"
sed -i '/cipher /d' "$SERVER"

# remove daemon/logging options (break docker)
sed -i '/daemon/d' "$SERVER"
sed -i '/log /d' "$SERVER"
sed -i '/log-append/d' "$SERVER"
sed -i 's#ca ca.ipvanish.com.crt#ca /config/ca.ipvanish.com.crt#g' "$SERVER"
sed -i 's#tls-auth ta.key#tls-auth /config/ta.key#g' "$SERVER" 2>/dev/null || true

# VERY IMPORTANT: remove ALL auth-user-pass lines
sed -i '/auth-user-pass/d' "$SERVER"

# add correct auth file
echo "auth-user-pass /config/auth.txt" >> "$SERVER"

# modern cipher negotiation
echo "data-ciphers AES-256-GCM:AES-128-GCM:AES-256-CBC" >> "$SERVER"
echo "data-ciphers-fallback AES-256-CBC" >> "$SERVER"

# routing
echo "redirect-gateway def1" >> "$SERVER"
echo "auth-nocache" >> "$SERVER"
echo "verb 3" >> "$SERVER"

########################
# start VPN FIRST
########################
openvpn --config "$SERVER" &
VPN_PID=$!

echo "Waiting for tunnel..."

# wait for tun0
for i in {1..30}; do
    if ip a show tun0 >/dev/null 2>&1; then
        echo "VPN tunnel established"
        break
    fi
    sleep 1
done

if ! ip a show tun0 >/dev/null 2>&1; then
    echo "VPN failed to start"
    exit 1
fi

########################
# NAT (this makes proxy actually use VPN)
########################
iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

########################
# start tinyproxy AFTER vpn
########################
echo "Starting tinyproxy..."
tinyproxy

########################
# keep container alive
########################
wait $VPN_PID
