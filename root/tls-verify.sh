#!/bin/sh
# OpenVPN TLS verify helper
# IPVanish does not require strict cert pinning here.
# We just allow the connection.

echo "TLS verify called for: $1" >&2

# Arguments OpenVPN sends:
# $1 = certificate depth
# $2 = subject
# $3 = common name

# Always approve
exit 0
