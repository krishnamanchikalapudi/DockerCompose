#!/usr/bin/env bash
set -e
arg="${1:-RESTART}"

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

tests(){
    ollama_tests
}
ollama_tests(){
    curl -s --max-time 5 http://localhost:11434/api/tags
    printf "\n\n"

    curl -s --max-time 5 -X POST http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{"model":"qwen3.5:0.8b","prompt":"What vaccines does an adult cat need? Be concise.","stream":false}' | jq '.response'
    printf "\n\n"

    curl -s --max-time 5 -X POST http://localhost:11434/api/embed -H "Content-Type: application/json" -d '{"model":"nomic-embed-text","input":"feline upper respiratory infection treatment"}' | jq '.embeddings[0][0:5]'
    printf "\n\n"

    curl -s --max-time 5 -X POST http://localhost:11434/api/show -H "Content-Type: application/json" -d '{"name":"qwen3.5:0.8b"}' | jq '{model:.modelfile,size:.size}'
    printf "\n\n"
}


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
        docker compose -f ./apps/ollama.yml up
        ;;
    STOP|DOWN)
        check_docker
        docker compose -f ./apps/ollama.yml down
        ;;
    RESTART)
        check_docker
        docker compose -f ./apps/ollama.yml restart
        ;;
    STATUS|PS)
        docker compose -f ./apps/ollama.yml ps
        ;;
    LOGS)
        docker compose -f ./apps/ollama.yml logs
        ;;
    TEST|TESTS)
        tests
        ;;
    *)
        echo "Usage: $0 <START|STOP|RESTART|STATUS|LOGS|TEST>"
        exit 1
        ;;
esac