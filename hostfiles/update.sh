#!/bin/bash
#
# Factorio Auto-Update Script with RCON Countdown
# Checks for new Factorio stable versions and updates with player warnings
#

set -euo pipefail

#=============================================================================
# CONFIGURATION - Update these to match your setup
#=============================================================================

# Docker configuration (from host)
CONTAINER_NAME="factorio" # from docker-compose.yml
COMPOSE_DIR="/home/factorio"  # Directory where docker-compose.yml lives on your host
COMPOSE_FILE="docker-compose.yml"
LOG_DIR="/var/log"

# RCON configuration
RCON_HOST="localhost"  # Docker host where mcrcon runs (usually localhost)
RCON_PORT="27015"
RCON_PASSWORD_FILE="${COMPOSE_DIR}/.secrets/RCON_PASSWORD.txt" #from your Docker host

# Countdown timings (in seconds)
SLEEP_AFTER_15MIN=600   # Wait 10 minutes after 15-min warning
SLEEP_AFTER_5MIN=240    # Wait 4 minutes after 5-min warning
SLEEP_AFTER_1MIN=60     # Wait 1 minute after 1-min warning

# Logging
LOG_FILE="$(LOG_DIR)/factorio-updates.log"

#=============================================================================
# FUNCTIONS
#=============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2
}

# Send RCON command to Factorio server
send_rcon() {
    local message="$1"
    local rcon_pass
    
    # Read RCON password from secrets file
    if [ ! -f "$RCON_PASSWORD_FILE" ]; then
        error "RCON password file not found: $RCON_PASSWORD_FILE"
        return 1
    fi
    
    rcon_pass=$(cat "$RCON_PASSWORD_FILE")
    
    # Send message via RCON
    echo "$message" | mcrcon -H "$RCON_HOST" -P "$RCON_PORT" -p "$rcon_pass" 2>&1 | tee -a "$LOG_FILE"
}

#=============================================================================
# MAIN SCRIPT
#=============================================================================

log "========================================="
log "Factorio Auto-Update Check Started"
log "========================================="

# Check if mcrcon is installed
if ! command -v mcrcon &> /dev/null; then
    error "mcrcon is not installed. Install with: sudo apt install mcrcon"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    error "jq is not installed. Install with: sudo apt install jq"
    exit 1
fi

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    error "docker compose is not available"
    exit 1
fi

# Fetch latest Factorio stable version from API
log "Fetching latest Factorio version from API..."
LATEST_VERSION=$(curl -s https://factorio.com/api/latest-releases | jq -r '.stable.headless')

if [ -z "$LATEST_VERSION" ] || [ "$LATEST_VERSION" == "null" ]; then
    error "Failed to fetch latest version from Factorio API"
    exit 1
fi

log "Latest stable version: $LATEST_VERSION"

# Get currently running version from container
log "Checking current running version..."
CURRENT_VERSION=$(docker exec "$CONTAINER_NAME" cat /opt/factorio/data/base/info.json 2>/dev/null | jq -r '.version' || echo "unknown")

if [ "$CURRENT_VERSION" == "unknown" ]; then
    error "Could not detect current version. Is container running?"
    exit 1
fi

log "Current running version: $CURRENT_VERSION"

# Compare versions
if [ "$LATEST_VERSION" == "$CURRENT_VERSION" ]; then
    log "Server is already running the latest version ($CURRENT_VERSION)"
    log "No update needed."
    exit 0
fi

log "UPDATE AVAILABLE: $CURRENT_VERSION -> $LATEST_VERSION"
log "Starting update countdown sequence..."

#=============================================================================
# COUNTDOWN SEQUENCE
#=============================================================================

# 15-minute warning
log "Sending 15-minute warning to players..."
send_rcon "[color=yellow]SERVER UPDATE NOTICE:[/color] Server will restart to update from version $CURRENT_VERSION to $LATEST_VERSION in 15 minutes. Please save your progress!"

sleep $SLEEP_AFTER_15MIN

# 5-minute warning
log "Sending 5-minute warning to players..."
send_rcon "[color=orange]SERVER UPDATE:[/color] Server updating in 5 MINUTES! Make sure to save your work!"

sleep $SLEEP_AFTER_5MIN

# 1-minute warning  
log "Sending 1-minute warning to players..."
send_rcon "[color=red]SERVER UPDATE:[/color] Server restarting in 1 MINUTE for version $LATEST_VERSION update!"

sleep $SLEEP_AFTER_1MIN

# Final warning
log "Sending final shutdown warning..."
send_rcon "[color=red][font=default-large-bold]SERVER SHUTTING DOWN NOW FOR UPDATE[/font][/color]"

sleep 5

#=============================================================================
# UPDATE PROCESS
#=============================================================================

log "Stopping container..."
cd "$COMPOSE_DIR" || exit 1
docker compose -f "$COMPOSE_FILE" down

log "Pulling new image (slautomaton/factorio:stable)..."
docker compose -f "$COMPOSE_FILE" pull

log "Starting updated container..."
docker compose -f "$COMPOSE_FILE" up -d

log "Waiting for server to fully start..."
sleep 30

# Verify update success
NEW_VERSION=$(docker exec "$CONTAINER_NAME" cat /opt/factorio/data/base/info.json 2>/dev/null | jq -r '.version' || echo "unknown")

if [ "$NEW_VERSION" == "$LATEST_VERSION" ]; then
    log "✓ SUCCESS: Server updated to version $NEW_VERSION"
    
    # Announce successful update to players (wait for server to be ready for RCON)
    sleep 15
    send_rcon "[color=green]Server updated successfully to version $NEW_VERSION! Welcome back![/color]"
else
    error "Update verification failed. Expected $LATEST_VERSION, got $NEW_VERSION"
    exit 1
fi

log "========================================="
log "Factorio Auto-Update Complete"
log "========================================="
