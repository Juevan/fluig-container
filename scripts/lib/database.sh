#!/bin/bash

# --- Driver JDBC e Verificação ---
setup_database_driver() {
    DB_DRIVER_CLASS="com.mysql.cj.jdbc.Driver"
    DB_DRIVER_URL="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar"
    DB_DRIVER_NAME="mysql-connector.jar"

    export DB_DRIVER_CLASS
    export DB_DRIVER_PATH="/tmp/$DB_DRIVER_NAME"
}

wait_database() {
    setup_database_driver
    echo "Aguardando banco ($DB_HOST:$DB_PORT)..."
    until (: < "/dev/tcp/$DB_HOST/$DB_PORT") 2>/dev/null; do sleep 2; done
    echo "Banco disponível."

    mkdir -p /tmp/fluig-installer
    if [ ! -f "$DB_DRIVER_PATH" ] && [ -n "$DB_DRIVER_URL" ]; then
        curl -L -s -o "$DB_DRIVER_PATH" "$DB_DRIVER_URL"
    fi
}
