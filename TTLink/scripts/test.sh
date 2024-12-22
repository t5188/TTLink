clear
echo "ip rules"
ip ru
echo ""
echo ""
echo "iptables -t mangle -L DNS2TUN -nv"
iptables -t mangle -L DNS2TUN -nv
echo ""
echo ""
echo "iptables -t filter -L TUN_FORWARD -nv"
iptables -t filter -L TUN_FORWARD -nv
echo ""
echo ""
echo "iptables -L OUTPUT -nv"
iptables -L OUTPUT -nv
echo ""
echo ""
echo "xray pid ($(pidof xray))"
echo "box pid ($(pidof sing-box))"