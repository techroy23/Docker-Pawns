#!/bin/bash
set -e

BIN_SDK_AMD64="/app/pawns-cli-amd64"
BIN_SDK_ARM64="/app/pawns-cli-arm64"
IP_CHECKER_URL="https://raw.githubusercontent.com/techroy23/IP-Checker/refs/heads/main/app.sh"
ENABLE_IP_CHECKER="${ENABLE_IP_CHECKER:-false}"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*"
}

arch=$(uname -m)
case "$arch" in
  x86_64)
    BIN_SDK="$BIN_SDK_AMD64"
    log " >>> An2Kin >>> Detected architecture: $arch, using $BIN_SDK"
    ;;
  aarch64|arm64)
    BIN_SDK="$BIN_SDK_ARM64"
    log " >>> An2Kin >>> Detected architecture: $arch, using $BIN_SDK"
    ;;
  *)
    log " >>> An2Kin >>> ERROR: Unsupported architecture: $arch"
    exit 1
    ;;
esac

setup_iptables() {
  log " >>> An2Kin >>> Setting up iptables and redsocks..."
  if ! iptables -t nat -L REDSOCKS -n >/dev/null 2>&1; then
    iptables -t nat -N REDSOCKS
  else
    iptables -t nat -F REDSOCKS
  fi
  iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d $host -j RETURN
  iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345

  if ! iptables -t nat -C OUTPUT -p tcp -j REDSOCKS 2>/dev/null; then
    iptables -t nat -A OUTPUT -p tcp -j REDSOCKS
  fi
}

cleanup() {
  log " >>> An2Kin >>> Cleaning up iptables and redsocks..."
  iptables -t nat -F REDSOCKS 2>/dev/null || true
  iptables -t nat -D OUTPUT -p tcp -j REDSOCKS 2>/dev/null || true
  iptables -t nat -X REDSOCKS 2>/dev/null || true
  kill $REDSOCKS_PID 2>/dev/null || true
}
trap cleanup EXIT

setup_proxy() {
  if [ -n "$PROXY" ]; then
    log " >>> An2Kin >>> External routing via proxy: $PROXY"

    host=$(echo "$PROXY" | cut -d: -f1)
    port=$(echo "$PROXY" | cut -d: -f2)

    cat >/etc/redsocks.conf <<EOF
base {
  log_debug = off;
  log_info = off;
  log = "stderr";
  daemon = off;
  redirector = iptables;
}

redsocks {
  local_ip = 0.0.0.0;
  local_port = 12345;
  ip = $host;
  port = $port;
  type = socks5;
}
EOF

    redsocks -c /etc/redsocks.conf >/dev/null 2>&1 &
    REDSOCKS_PID=$!

    setup_iptables
  else
    log " >>> An2Kin >>> Proxy not set, proceeding with direct connection"
  fi
}

check_ip() {
  if [ "$ENABLE_IP_CHECKER" = "true" ]; then
    log " >>> An2Kin >>> Checking current public IP..."
    if curl -fsSL "$IP_CHECKER_URL" | sh; then
      log " >>> An2Kin >>> IP checker script ran successfully"
    else
      log " >>> An2Kin >>> WARNING: Could not fetch or execute IP checker script"
    fi
  else
    log " >>> An2Kin >>> IP checker disabled (ENABLE_IP_CHECKER=$ENABLE_IP_CHECKER)"
  fi
}

if [ -z "${EMAIL:-}" ]; then
  log " >>> An2Kin >>> ERROR: EMAIL environment variable is not set."
  exit 1
fi

if [ -z "${PASSWORD:-}" ]; then
  log " >>> An2Kin >>> ERROR: PASSWORD environment variable is not set."
  exit 1
fi

while true; do
    setup_proxy
    check_ip
    log " >>> An2Kin >>> Starting binary..."
    exec $BIN_SDK -email=$EMAIL -password=$PASSWORD -accept-tos &
    PID=$!
    sleep 43200 &
    SLEEP_PID=$!
    wait -n $PID $SLEEP_PID
    if kill -0 $PID 2>/dev/null; then
        log " >>> An2Kin >>> Time elapsed, killing process $PID"
        kill -TERM $PID
        wait $PID || true
    else
        log " >>> An2Kin >>> Process exited, restarting..."
    fi
    kill $SLEEP_PID 2>/dev/null || true
done