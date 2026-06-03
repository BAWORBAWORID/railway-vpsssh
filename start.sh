#!/bin/bash

echo "[*] Detecting public IP..."
PUBLIC_IP=""
for url in \
    "https://api.ipify.org" \
    "https://ifconfig.me" \
    "https://icanhazip.com" \
    "https://checkip.amazonaws.com"; do
    PUBLIC_IP=$(curl -s --max-time 5 "$url" 2>/dev/null | tr -d '[:space:]')
    if [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "[*] Public IP: $PUBLIC_IP"
        break
    fi
done

if [[ -z "$PUBLIC_IP" ]]; then
    PUBLIC_IP=$(ip route | awk '/default/ {print $3}' | head -1)
    echo "[!] Fallback IP: $PUBLIC_IP"
fi

FRP_PORT="${FRP_PORT:-7000}"
REMOTE_PORT="${REMOTE_PORT:-6022}"
VNC_PORT="${VNC_PORT:-5901}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
VNC_RESOLUTION="${VNC_RESOLUTION:-1280x720}"

mkdir -p /etc/frp

# FRP server config
cat > /etc/frp/frps.toml << EOF
bindPort = $FRP_PORT
EOF

# FRP client config - expose SSH + noVNC
cat > /etc/frp/frpc.toml << EOF
serverAddr = "127.0.0.1"
serverPort = $FRP_PORT

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = $REMOTE_PORT

[[proxies]]
name = "novnc"
type = "tcp"
localIP = "127.0.0.1"
localPort = $NOVNC_PORT
remotePort = 6080
EOF

echo "[*] Starting frps..."
frps -c /etc/frp/frps.toml &
sleep 2

echo "[*] Starting SSH..."
/usr/sbin/sshd

echo "[*] Starting VNC server..."
vncserver \
    -localhost no \
    -SecurityTypes None \
    -geometry $VNC_RESOLUTION \
    --I-KNOW-THIS-IS-INSECURE \
    :1 &
sleep 3

echo "[*] Starting noVNC..."
openssl req -new -subj "/C=ID" -x509 -days 365 -nodes \
    -out /root/self.pem -keyout /root/self.pem 2>/dev/null

websockify -D \
    --web=/usr/share/novnc/ \
    --cert=/root/self.pem \
    $NOVNC_PORT localhost:$VNC_PORT

echo "[*] Starting frpc..."
frpc -c /etc/frp/frpc.toml &

echo ""
echo "======================================="
echo "  VPS WINDOWS 10 DESKTOP - READY"
echo "======================================="
echo "  [SSH]"
echo "  Host : $PUBLIC_IP"
echo "  Port : $REMOTE_PORT"
echo "  User : root"
echo "  Pass : Codex"
echo ""
echo "  [Desktop / noVNC]"
echo "  URL  : http://$PUBLIC_IP:$NOVNC_PORT/vnc.html"
echo "======================================="

tail -f /dev/null
