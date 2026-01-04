#!/bin/bash
# -------------------------------
# 🔁 IPHopper - IP Changing Tool
# Termux/Linux Friendly Version
# Banner by 𝙕𝙮𝙧𝙤𝙉𝙚𝙭𝙖𝙡
# -------------------------------

clear

# ---------- Banner ----------
echo -e "\e[1;35m╔══════════════════════════════════╗"
echo -e "║      🔁 𝙕𝙮𝙧𝙤𝙉𝙚𝙭𝙖𝙡 IP Changer 🔁      ║"
echo -e "║      ⚡ Powered by Tor & Privoxy ⚡   ║"
echo -e "╚══════════════════════════════════╝\e[0m"
echo ""

# ---------- Dependency Check ----------
DEPS=(tor privoxy curl nc)
for cmd in "${DEPS[@]}"; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo -e "\e[1;31m[!] $cmd not found! Install it first.\e[0m"
        exit 1
    fi
done

# ---------- Cleanup ----------
pkill tor >/dev/null 2>&1
pkill privoxy >/dev/null 2>&1
rm -rf ~/.tor_multi ~/.privoxy
mkdir -p ~/.tor_multi ~/.privoxy

# ---------- Tor Nodes ----------
PORTS=(9050 9060 9070 9080 9090)
CONTROL_PORTS=(9051 9061 9071 9081 9091)

echo -e "\e[1;32m[+] Launching Tor Nodes & Proxy...\e[0m"
for i in {0..4}; do
    TOR_DIR="$HOME/.tor_multi/tor$i"
    mkdir -p "$TOR_DIR"
    cat <<EOF > "$TOR_DIR/torrc"
SocksPort ${PORTS[$i]}
ControlPort ${CONTROL_PORTS[$i]}
DataDirectory $TOR_DIR
CookieAuthentication 0
EOF
    tor -f "$TOR_DIR/torrc" >/dev/null 2>&1 &
    sleep 2
done

# ---------- Privoxy ----------
cat <<EOF > "$HOME/.privoxy/config"
listen-address 127.0.0.1:8118
EOF
for port in "${PORTS[@]}"; do
    echo "forward-socks5 / 127.0.0.1:$port ." >> "$HOME/.privoxy/config"
done
privoxy "$HOME/.privoxy/config" >/dev/null 2>&1 &

# ---------- IP Rotation Interval ----------
echo -ne "\e[1;36mEnter IP rotation interval (seconds, min 5s): \e[0m"
read -r ROTATION_TIME
if [[ ! "$ROTATION_TIME" =~ ^[0-9]+$ ]] || [[ "$ROTATION_TIME" -lt 5 ]]; then
    echo -e "\e[1;33mInvalid input! Using default 10s.\e[0m"
    ROTATION_TIME=10
fi

# ---------- Infinite IP Rotation ----------
while true; do
    for ctrl_port in "${CONTROL_PORTS[@]}"; do
        echo -e "AUTHENTICATE \"\"\r\nSIGNAL NEWNYM\r\nQUIT" | nc 127.0.0.1 $ctrl_port >/dev/null 2>&1
    done
    NEW_IP=$(curl --proxy http://127.0.0.1:8118 -s https://api64.ipify.org)
    echo -e "\e[1;32m🌐 New IP: $NEW_IP ✅\e[0m"
    echo -e "\e[1;34m[Proxy]: 127.0.0.1:8118 🛰️\e[0m"
    sleep "$ROTATION_TIME"
done