#!/usr/bin/env bash
set -e
arg="${1:-ALL}"

banner_bootcamp(){
    cat << 'EOF_BANNER'
======================================================================================
    oooooooooo.     .oooooo.     .oooooo.   oooo    oooo oooooooooooo ooooooooo.     
   `888'   `Y8b   d8P'  `Y8b   d8P'  `Y8b  `888   .8P'  `888'     `8 `888   `Y88.    
    888      888 888      888 888           888  d8'     888          888   .d88'    
    888      888 888      888 888           88888[       888oooo8     888ooo88P'     
    888      888 888      888 888           888`88b.     888          888`88b.       
    888     d88' `88b    d88' `88b    ooo   888  `88b.   888       o  888  `88b.     
    o888bood8P'    `Y8bood8P'   `Y8bood8P'  o888o  o888o o888ooooood8 o888o  o888o   
======================================================================================
EOF_BANNER
}

check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Warning: Cannot connect to the Docker daemon. Make sure Docker is running." >&2
    fi
}

wait_for_service_healthy() {
    local compose_file="$1"
    local service_name="$2"
    local retries="${3:-60}"
    local delay="${4:-5}"
    local i

    for ((i=1; i<=retries; i++)); do
        local container_id
        container_id=$(docker compose -f "$compose_file" ps -q "$service_name" 2>/dev/null || true)
        if [[ -n "$container_id" ]]; then
            local status
            status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null || true)
            if [[ "$status" == "healthy" || "$status" == "running" ]]; then
                return 0
            fi
        fi
        sleep "$delay"
    done

    echo "Timed out waiting for $service_name to become healthy." >&2
    return 1
}

compose_up() {
    local compose_file="$1"
    docker compose -f "$compose_file" up -d
}

compose_down() {
    local compose_file="$1"
    docker compose -f "$compose_file" down
}

banner_bootcamp

# Normalize argument to uppercase
arg=$(printf '%s' "$arg" | tr '[:lower:]' '[:upper:]' | xargs)
echo "User Action: ${arg}"

case $arg in
    ALL|START|UP|DEFAULT)
        check_docker
        compose_up ./docker-compose.yml
        wait_for_service_healthy ./docker-compose.yml ollama
        wait_for_service_healthy ./docker-compose.yml postgresql
        wait_for_service_healthy ./docker-compose.yml valkey
        wait_for_service_healthy ./docker-compose.yml mlflow
        ;;
    STOP|DOWN)
        check_docker
        compose_down ./docker-compose.yml
        ;;
    RESTART)
        check_docker
        compose_up ./docker-compose.yml
        wait_for_service_healthy ./docker-compose.yml ollama
        wait_for_service_healthy ./docker-compose.yml postgresql
        wait_for_service_healthy ./docker-compose.yml valkey
        wait_for_service_healthy ./docker-compose.yml mlflow
        ;;
    LOGS)
        docker compose -f ./docker-compose.yml logs --tail=200
        ;;
    OLLAMA)
        compose_up ./apps/ollama.yml
        wait_for_service_healthy ./apps/ollama.yml ollama
        ;;
    MLFLOW)
        docker compose -f ./apps/pgvector.yml -f ./apps/mlflow.yml up -d
        wait_for_service_healthy ./apps/pgvector.yml postgresql
        wait_for_service_healthy ./apps/mlflow.yml mlflow
        ;;
    PGVECTOR)
        compose_up ./apps/pgvector.yml
        wait_for_service_healthy ./apps/pgvector.yml postgresql
        ;;
    VALKEY)
        compose_up ./apps/valkey.yml
        wait_for_service_healthy ./apps/valkey.yml valkey
        ;;
    STATUS)
        docker compose -f ./docker-compose.yml ps
        ;;
    *)
        echo "Usage: $0 <START|STOP|RESTART|STATUS|LOGS|OLLAMA|MLFLOW|PGVECTOR|VALKEY>"
        exit 1
        ;;
esac
