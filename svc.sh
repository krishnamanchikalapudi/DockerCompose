#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.yml"

arg="${1:-START}"

banner_bootcamp(){
    cat << 'EOF'
======================================================================================
    oooooooooo.     .oooooo.     .oooooo.   oooo    oooo oooooooooooo ooooooooo.     
   `888'   `Y8b   d8P'  `Y8b   d8P'  `Y8b  `888   .8P'  `888'     `8 `888   `Y88.    
    888      888 888      888 888           888  d8'     888          888   .d88'    
    888      888 888      888 888           88888[       888oooo8     888ooo88P'     
    888      888 888      888 888           888`88b.     888          888`88b.       
    888     d88' `88b    d88' `88b    ooo   888  `88b.   888       o  888  `88b.     
    o888bood8P'    `Y8bood8P'   `Y8bood8P'  o888o  o888o o888ooooood8 o888o  o888o   
======================================================================================
EOF
}

ollama_tests(){
    
}

# Resolve Docker Compose command (docker compose plugin vs legacy docker-compose)
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE=(docker compose)
elif command -v docker-compose >/dev/null 2>&1; then
    DOCKER_COMPOSE=(docker-compose)
else
    echo "Error: Neither 'docker compose' nor 'docker-compose' is available." >&2
    exit 1
fi

check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Warning: Cannot connect to the Docker daemon. Make sure Docker is running." >&2
    fi
}

banner_bootcamp

# Normalize argument to uppercase
arg=$(printf '%s' "$arg" | tr '[:lower:]' '[:upper:]' | xargs)
echo "User Action: ${arg}"

case $arg in
    START|UP)
        check_docker
        "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" up -d
        ;;
    STOP|DOWN)
        check_docker
        "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" down
        ;;
    RESTART)
        check_docker
        "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" restart
        ;;
    STATUS|PS)
        check_docker
        "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" ps
        ;;
    LOGS)
        check_docker
        "${DOCKER_COMPOSE[@]}" -f "$COMPOSE_FILE" logs -f
        ;;
    *)
        echo "Usage: $0 <START|STOP|RESTART|STATUS|LOGS>"
        exit 1
        ;;
esac