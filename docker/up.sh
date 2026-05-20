#!/bin/bash

# Verifica pré-requisitos
if ! command -v docker &> /dev/null; then
    echo "ERRO: Docker não encontrado. Instale em https://docs.docker.com/get-docker/"
    exit 1
fi

# Verifica se o instalador está presente
if [ -z "$(ls -A ../installer-package 2>/dev/null)" ]; then
    echo "AVISO: A pasta installer-package/ está vazia."
    echo "       Descompacte o instalador do Fluig antes de continuar."
    exit 1
fi

echo "Iniciando ambiente Fluig Community Container..."
echo "  Solr  : $(grep '^INSTALL_SOLR' .env | cut -d= -f2)"
echo "  Node  : $(grep '^INSTALL_NODE' .env | cut -d= -f2)"
echo ""

if docker compose version > /dev/null 2>&1; then
    docker compose up -d --build "$@"
elif docker-compose --version > /dev/null 2>&1; then
    docker-compose up -d --build "$@"
else
    echo "ERRO: Docker Compose não encontrado!"
    exit 1
fi

echo ""
echo "Ambiente iniciado. Acompanhe a instalação com:"
echo "  docker logs -f fluig"
echo ""
echo "Acesse em: http://localhost:$(grep '^PORT_APP' .env | cut -d= -f2)/portal"
