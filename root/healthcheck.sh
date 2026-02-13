#!/bin/sh

IP=$(curl -s --max-time 5 https://api.ipify.org)
[ -z "$IP" ] && exit 1

exit 0
