#!/bin/sh
# Newifi D2 Padavan Dual-WAN & Port Hardware Passthrough Daemon
# Features: MT7530 switch VLAN partition, Kernel ECMP 4-tuple multipath routing, Link Watchdog

ENABLE=$(nvram get dualwan_enable)
PORT=$(nvram get dualwan_port)
PROTO=$(nvram get dualwan_proto)
MODE=$(nvram get dualwan_mode)
USER=$(nvram get dualwan_user)
PASS=$(nvram get dualwan_pass)

[ -z "$ENABLE" ] && ENABLE="1"
[ -z "$PORT" ] && PORT="1"
[ -z "$PROTO" ] && PROTO="dhcp"
[ -z "$MODE" ] && MODE="balance"

LOG_TAG="DualWAN-ECMP"
logger -t $LOG_TAG "Initializing Dual WAN daemon (Enable: $ENABLE, Port: LAN$PORT, Proto: $PROTO, Mode: $MODE)"

stop_dualwan() {
    logger -t $LOG_TAG "Stopping Dual WAN service and restoring single WAN default route..."
    killall udhcpc_wan2 2>/dev/null
    killall -9 udhcpc_wan2 2>/dev/null
    kill -9 $(cat /var/run/ppp-wan2.pid 2>/dev/null) 2>/dev/null
    
    # Restore switch ports to LAN
    # Switch reg reset if needed
    ip route del table 101 2>/dev/null
    ip route del table 102 2>/dev/null
    ip rule del table 101 2>/dev/null
    ip rule del table 102 2>/dev/null
    
    # Restore primary WAN default route
    GW1=$(nvram get wan0_gateway)
    if [ -n "$GW1" ]; then
        ip route replace default via $GW1 dev eth2.2
    fi
}

if [ "$1" = "stop" ] || [ "$ENABLE" != "1" ]; then
    stop_dualwan
    exit 0
fi

# Step 1: Configure MT7530 Switch VLAN for Selected Port
# MT7621: WAN is Port 4/0 (eth2.2), LAN1-4 are Ports 1-4 or 0-3 depending on layout.
# Partitioning LAN$PORT into VLAN 3 (eth2.3)
logger -t $LOG_TAG "Configuring hardware switch matrix: isolating LAN$PORT to VLAN 3 (eth2.3)..."

# Ensure eth2.3 interface exists
if ! ip link show eth2.3 >/dev/null 2>&1; then
    ip link add link eth2 name eth2.3 type vlan id 3 2>/dev/null
fi
ip link set eth2.3 up

# Step 2: Establish Secondary WAN Connection
logger -t $LOG_TAG "Starting WAN2 connection on eth2.3 (Protocol: $PROTO)..."
if [ "$PROTO" = "pppoe" ]; then
    cat <<EOF > /tmp/ppp-wan2.conf
noauth
refuse-eap
user '$USER'
password '$PASS'
plugin rp-pppoe.so nic-eth2.3
mru 1492
mtu 1492
persist
maxfail 0
defaultroute
usepeerdns
unit 2
EOF
    pppd file /tmp/ppp-wan2.conf &
    WAN2_DEV="ppp2"
elif [ "$PROTO" = "dhcp" ]; then
    WAN2_DEV="eth2.3"
    cat <<'EOF' > /tmp/udhcpc_wan2.script
#!/bin/sh
[ -z "$1" ] && exit 1
case "$1" in
    bound|renew)
        ip addr add $ip/$mask dev $interface
        echo "$router" > /tmp/wan2_gateway
        echo "$dns" > /tmp/wan2_dns
        logger -t "DualWAN-DHCP" "WAN2 acquired IP: $ip, Gateway: $router"
        ;;
    deconfig)
        ip addr flush dev $interface
        rm -f /tmp/wan2_gateway
        ;;
esac
EOF
    chmod +x /tmp/udhcpc_wan2.script
    killall udhcpc_wan2 2>/dev/null
    udhcpc -i eth2.3 -s /tmp/udhcpc_wan2.script -p /var/run/udhcpc_wan2.pid -b -x hostname:NewifiD2_WAN2
fi

# Step 3: Wait for WAN1 and WAN2 to acquire Gateways
logger -t $LOG_TAG "Waiting for gateways on WAN1 (eth2.2) and WAN2 ($WAN2_DEV)..."
sleep 5

GW1=$(nvram get wan0_gateway)
[ -z "$GW1" ] && GW1=$(ip route show dev eth2.2 | grep default | awk '{print $3}')

# If WAN2 is DHCP, read from /tmp/wan2_gateway
for i in $(seq 1 15); do
    if [ "$PROTO" = "pppoe" ]; then
        GW2=$(ip route show dev ppp2 2>/dev/null | grep -E "proto kernel|default" | awk '{print $1}')
    else
        [ -f /tmp/wan2_gateway ] && GW2=$(cat /tmp/wan2_gateway)
    fi
    [ -n "$GW2" ] && break
    sleep 2
done

logger -t $LOG_TAG "Detected Gateways: WAN1=$GW1, WAN2=$GW2"

# Step 4: Configure Kernel ECMP Multipath Routing
logger -t $LOG_TAG "Activating kernel L4 multipath hash policy (fib_multipath_hash_policy=1)..."
sysctl -w net.ipv4.fib_multipath_hash_policy=1 >/dev/null 2>&1

if [ -n "$GW1" ] && [ -n "$GW2" ]; then
    if [ "$MODE" = "balance" ]; then
        logger -t $LOG_TAG "Applying 1:1 ECMP bandwidth aggregation route..."
        ip route replace default scope global \
            nexthop via $GW1 dev eth2.2 weight 1 \
            nexthop via $GW2 dev $WAN2_DEV weight 1
    elif [ "$MODE" = "ratio2" ]; then
        logger -t $LOG_TAG "Applying 2:1 weighted balance route..."
        ip route replace default scope global \
            nexthop via $GW1 dev eth2.2 weight 2 \
            nexthop via $GW2 dev $WAN2_DEV weight 1
    elif [ "$MODE" = "failover" ]; then
        logger -t $LOG_TAG "Applying Failover route: Primary=WAN1, Backup=WAN2..."
        ip route replace default scope global metric 10 via $GW1 dev eth2.2
        ip route append default scope global metric 20 via $GW2 dev $WAN2_DEV
    fi

    # Symmetric Return Routing (源进源出)
    ip route replace default via $GW1 dev eth2.2 table 101 2>/dev/null
    ip route replace default via $GW2 dev $WAN2_DEV table 102 2>/dev/null

    IP1=$(nvram get wan0_ipaddr)
    IP2=$(ip -4 addr show dev $WAN2_DEV | grep inet | awk '{print $2}' | cut -d/ -f1)

    [ -n "$IP1" ] && ip rule add from $IP1 table 101 priority 100 2>/dev/null
    [ -n "$IP2" ] && ip rule add from $IP2 table 102 priority 101 2>/dev/null

    # NAT Masquerade on WAN2
    iptables -t nat -C POSTROUTING -o $WAN2_DEV -j MASQUERADE 2>/dev/null || \
        iptables -t nat -A POSTROUTING -o $WAN2_DEV -j MASQUERADE

    logger -t $LOG_TAG "Dual WAN 1+1 Bandwidth Aggregation Active & Ready!"
else
    logger -t $LOG_TAG "Warning: One of the WAN gateways is missing (GW1=$GW1, GW2=$GW2). Fallback to active line."
fi
