#!/bin/sh

# SSClash / Mihomo Memory Optimizer for OpenWrt
# https://github.com/F5GO/F5GO-Mihomo-stuff
#
# Adds Go runtime memory tuning variables to the SSClash procd service:
#
#   GOGC=50
#   GOMEMLIMIT=96MiB
#
# This is useful on memory-constrained OpenWrt routers where Mihomo can
# gradually consume a large part of the available RAM.
#
# GOMEMLIMIT is a soft Go runtime memory limit, NOT a hard process/RSS limit.
# GOGC=50 makes Go's garbage collector run more aggressively than the
# default GOGC=100.
#
# Usage:
#   chmod +x ssclash-memory-limit.sh
#   ./ssclash-memory-limit.sh
#
# Custom values:
#   ./ssclash-memory-limit.sh 50 96MiB
#
# Example for a router with more RAM:
#   ./ssclash-memory-limit.sh 75 160MiB
#
# Restore:
#   cp /etc/init.d/ssclash.bak /etc/init.d/ssclash
#   /etc/init.d/ssclash restart

set -u

INIT="/etc/init.d/ssclash"

GOGC_VALUE="${1:-50}"
GOMEMLIMIT_VALUE="${2:-96MiB}"

echo "========================================"
echo " SSClash / Mihomo Memory Optimizer"
echo " F5GO-Mihomo-stuff"
echo "========================================"
echo
echo "GOGC       = $GOGC_VALUE"
echo "GOMEMLIMIT = $GOMEMLIMIT_VALUE"
echo

# ------------------------------------------------------------
# Check environment
# ------------------------------------------------------------

if [ "$(id -u)" != "0" ]; then
    echo "ERROR: This script must be run as root."
    exit 1
fi

if [ ! -f "$INIT" ]; then
    echo "ERROR: SSClash init script not found:"
    echo "       $INIT"
    exit 1
fi

if ! grep -q 'SSCLASH_ROOT' "$INIT"; then
    echo "ERROR: This does not look like a supported SSClash init script."
    echo "       SSCLASH_ROOT was not found."
    exit 1
fi

# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------

BACKUP="${INIT}.bak"

if [ ! -f "$BACKUP" ]; then
    cp "$INIT" "$BACKUP"

    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create backup."
        exit 1
    fi

    echo "Backup created:"
    echo "  $BACKUP"
else
    echo "Backup already exists:"
    echo "  $BACKUP"
fi

echo

# ------------------------------------------------------------
# Remove previous F5GO memory settings
# ------------------------------------------------------------

sed -i \
    -e '/procd_append_param env GOGC=/d' \
    -e '/procd_append_param env GOMEMLIMIT=/d' \
    "$INIT"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to modify $INIT"
    exit 1
fi

# ------------------------------------------------------------
# Add Go runtime memory settings
# ------------------------------------------------------------

sed -i "/procd_set_param env SSCLASH_ROOT/a\\
\\tprocd_append_param env GOGC=\"$GOGC_VALUE\"\\
\\tprocd_append_param env GOMEMLIMIT=\"$GOMEMLIMIT_VALUE\"" "$INIT"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to add memory settings."
    exit 1
fi

echo "Memory settings added to SSClash:"
echo

grep -n -E 'SSCLASH_ROOT|GOGC|GOMEMLIMIT' "$INIT"

echo

# ------------------------------------------------------------
# Restart SSClash
# ------------------------------------------------------------

echo "Restarting SSClash..."

"$INIT" restart

if [ $? -ne 0 ]; then
    echo "ERROR: SSClash restart failed."
    exit 1
fi

# Give SSClash time to start Mihomo.
sleep 5

# ------------------------------------------------------------
# Find Mihomo / Clash
# ------------------------------------------------------------

PID=""

i=0

while [ "$i" -lt 10 ]; do
    PID="$(pgrep -f '^/opt/clash/bin/clash ' 2>/dev/null | head -n 1)"

    if [ -n "$PID" ]; then
        break
    fi

    sleep 2
    i=$((i + 1))
done

echo

if [ -z "$PID" ]; then
    echo "WARNING: SSClash was restarted, but Mihomo/Clash"
    echo "         was not detected yet."
    echo
    echo "Check manually with:"
    echo "  pgrep -af 'clash|mihomo'"
    echo
    echo "The settings are installed and will be inherited"
    echo "when SSClash starts Mihomo."
    exit 0
fi

echo "Mihomo detected:"
echo "  PID: $PID"
echo

# ------------------------------------------------------------
# Verify environment
# ------------------------------------------------------------

echo "Checking Mihomo environment..."
echo

ENV_OUTPUT="$(
    cat "/proc/$PID/environ" 2>/dev/null |
        tr '\0' '\n' |
        grep -E '^(GOGC|GOMEMLIMIT)='
)"

echo "$ENV_OUTPUT"
echo

GOGC_OK=0
GOMEMLIMIT_OK=0

echo "$ENV_OUTPUT" | grep -q "^GOGC=${GOGC_VALUE}$" &&
    GOGC_OK=1

echo "$ENV_OUTPUT" | grep -q "^GOMEMLIMIT=${GOMEMLIMIT_VALUE}$" &&
    GOMEMLIMIT_OK=1

if [ "$GOGC_OK" -ne 1 ] || [ "$GOMEMLIMIT_OK" -ne 1 ]; then
    echo "WARNING: Mihomo is running, but one or more"
    echo "         environment variables were not inherited."
    echo
    echo "Expected:"
    echo "  GOGC=$GOGC_VALUE"
    echo "  GOMEMLIMIT=$GOMEMLIMIT_VALUE"
    exit 1
fi

# ------------------------------------------------------------
# Show memory status
# ------------------------------------------------------------

echo "Current Mihomo memory:"
echo

grep -E 'VmRSS|RssAnon|RssFile|VmData' "/proc/$PID/status" 2>/dev/null

echo
echo "System memory:"
echo

free -h

echo
echo "========================================"
echo " SUCCESS"
echo "========================================"
echo
echo "Mihomo is now running with:"
echo
echo "  GOGC=$GOGC_VALUE"
echo "  GOMEMLIMIT=$GOMEMLIMIT_VALUE"
echo
echo "NOTE:"
echo "GOMEMLIMIT is a Go runtime soft memory limit."
echo "It does NOT guarantee that Mihomo RSS will stay"
echo "below $GOMEMLIMIT_VALUE."
echo
echo "Original SSClash init script:"
echo "  $BACKUP"
echo
