#!/bin/bash

# Usage:
# ./hostbgp-config.sh [ASN] <INTERFACE1>[,<INTERFACE2>...] <VIP1> [<VIP2> ... <VIPn>]

OUTPUT_FILE="/etc/frr/frr.conf"

DEFAULT_ASN=64999

# Validate ASN
function valid_asn() {
  [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le 4294967295 ]
}

# Validate IPv4 /32
function valid_ipv4_32() {
  [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/32$ ]] || return 1
  IP="${1%/32}"
  IFS=. read -r a b c d <<< "$IP"
  for octet in $a $b $c $d; do
    [ "$octet" -ge 0 ] && [ "$octet" -le 255 ] || return 1
  done
  return 0
}

ASN="$DEFAULT_ASN"
if valid_asn "$1"; then
  ASN="$1"
  shift
fi

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 [ASN] <INTERFACE1>[,<INTERFACE2>...] <VIP1> [<VIP2> ... <VIPn>]"
  echo "VIPs should be IPv4 /32 addresses"
  echo "ASN will default to 64999 if not provided"
  exit 1
fi

IFS=',' read -ra INTERFACES <<< "$1"
shift

for IFACE in "${INTERFACES[@]}"; do
  if [ -z "$IFACE" ]; then
    echo "Invalid interface specification."
    exit 1
  fi
done

VIP_CONFIG=""
NETWORK_CONFIG=""
NEIGHBOR_CONFIG=""

for IFACE in "${INTERFACES[@]}"; do
  NEIGHBOR_CONFIG+=" neighbor $IFACE interface remote-as external
"
done

for VIP in "$@"; do
  if ! valid_ipv4_32 "$VIP"; then
    echo "Invalid VIP: $VIP (hint: make sure to add the /32 prefix length)"
    exit 1
  fi
  VIP_CONFIG+=" ip address $VIP
"
  NETWORK_CONFIG+="  network $VIP
"
done

cat <<EOF > "$OUTPUT_FILE"
interface lo
$VIP_CONFIG!
router bgp $ASN
 no bgp ebgp-requires-policy
 bgp bestpath as-path multipath-relax
 timers bgp 3 9
$NEIGHBOR_CONFIG address-family ipv4 unicast
  maximum-paths 4
$NETWORK_CONFIG !
!
EOF
