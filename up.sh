#!/bin/bash

# Determina o diretório onde o script está localizado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Verifica pré-requisitos
if ! command -v docker &> /dev/null; then
    echo "ERRO: Docker não encontrado. Instale em https://docs.docker.com/get-docker/"
    exit 1
fi

# Verifica se o instalador está presente
if [ -z "$(ls -A installer-package 2>/dev/null)" ]; then
    echo "AVISO: A pasta installer-package/ está vazia."
    echo "       Descompacte o instalador do Fluig antes de continuar."
    exit 1
fi

# Carrega variáveis de ambiente
if [ -f .env ]; then
    # shellcheck disable=SC1091
    source .env
fi

echo "Iniciando ambiente Fluig Community Container..."
echo "  Solr  : ${INSTALL_SOLR:-true}"
echo "  Node  : ${INSTALL_NODE:-true}"
echo "  E-mail: ${ENABLE_MAIL:-true}"
echo ""

if [ "${ENABLE_MAIL:-true}" = "true" ]; then
    export COMPOSE_PROFILES="mail"
else
    export COMPOSE_PROFILES=""
fi

# Executa o docker compose

if docker compose version &>/dev/null; then
    docker compose up -d --build "$@"
elif command -v docker-compose &>/dev/null; then
    docker-compose up -d --build "$@"
else
    echo "ERRO: Docker Compose não encontrado!"
    exit 1
fi

echo -e "\nAmbiente iniciado. Acompanhe a instalação com:"
echo "  docker logs -f fluig"
echo -e "\nAcesse em: http://localhost:${PORT_APP:-8080}/portal"
