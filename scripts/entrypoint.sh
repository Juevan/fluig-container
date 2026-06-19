#!/bin/bash

set -e

# --- Export de variáveis com fallbacks padrão para o envsubst e runtime ---
export DB_TYPE=${DB_TYPE:-"mysql"}
export DB_HOST=${DB_HOST:-"db"}
export DB_PORT=${DB_PORT:-"3306"}
export DB_NAME=${DB_NAME:-"fluig"}
export DB_USER=${DB_USER:-"fluig"}
export DB_PASSWORD=${DB_PASSWORD:-"fluig"}
export FLUIG_INSTALL_PATH=${FLUIG_INSTALL_PATH:-"/opt/totvs/fluig"}
export INSTALL_SOLR=${INSTALL_SOLR:-"true"}
export INSTALL_NODE=${INSTALL_NODE:-"true"}
export POOL_DS_MIN=${POOL_DS_MIN:-"10"}
export POOL_DS_MAX=${POOL_DS_MAX:-"100"}
export JVM_MIN_HEAP=${JVM_MIN_HEAP:-"2048"}
export JVM_MAX_HEAP=${JVM_MAX_HEAP:-"4096"}
export POOL_EJB=${POOL_EJB:-"20"}
export LS_HOST=${LS_HOST:-"127.0.0.1"}
export LS_PORT=${LS_PORT:-"5555"}
export NODE_HOST=${NODE_HOST:-"localhost"}
export PORT_REALTIME=${PORT_REALTIME:-"8888"}
export PORT_CHAT=${PORT_CHAT:-"7070"}
export PORT_SOLR=${PORT_SOLR:-"8983"}
export PORT_APP=${PORT_APP:-"8080"}
export EMAIL_HOST=${EMAIL_HOST:-"mailpit"}
export EMAIL_PORT=${EMAIL_PORT:-"1025"}
export EMAIL_SENDER=${EMAIL_SENDER:-"fluig@localhost"}
export MAIL_FROM=${MAIL_FROM:-"fluig@localhost"}
export MAIL_PERSONAL=${MAIL_PERSONAL:-"Fluig"}
export MAIL_USER=${MAIL_USER:-""}
export MAIL_PASSWORD=${MAIL_PASSWORD:-""}

# --- Export de variáveis específicas de runtime do JBoss/Wildfly ---
export FLUIG_SERVER_MEMORY_MIN="${JVM_MIN_HEAP}m"
export FLUIG_SERVER_MEMORY_MAX="${JVM_MAX_HEAP}m"
export FLUIG_CONFIG_DATABASE_MIN_POOL_SIZE="${POOL_DS_MIN}"
export FLUIG_CONFIG_DATABASE_MAX_POOL_SIZE="${POOL_DS_MAX}"
export FLUIG_CONFIG_DATABASE_MIN_POOL_SIZE_RO="${POOL_DS_MIN}"
export FLUIG_CONFIG_DATABASE_MAX_POOL_SIZE_RO="${POOL_DS_MAX}"

# --- Carregar bibliotecas modulares ---
for lib in database installer xml solr jboss realtime; do
    # shellcheck disable=SC1090
    source "/installer/scripts/lib/${lib}.sh"
done

# --- Orquestração ---
wait_database
install_fluig
patch_xml
start_solr
start_jboss
start_realtime

echo "Todos os serviços iniciados."

tail -f /tmp/jboss.log "$FLUIG_INSTALL_PATH/appserver/standalone/log/server.log" 2>/dev/null