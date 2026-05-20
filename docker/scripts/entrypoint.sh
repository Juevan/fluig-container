#!/bin/bash

# --- Driver JDBC ---
case "$DB_TYPE" in
    mysql)
        DB_DRIVER_CLASS="com.mysql.cj.jdbc.Driver"
        DB_DRIVER_URL="https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.0.33/mysql-connector-j-8.0.33.jar"
        DB_DRIVER_NAME="mysql-connector.jar" ;;
    postgres|postgresql)
        DB_DRIVER_CLASS="org.postgresql.Driver"
        DB_DRIVER_URL="https://jdbc.postgresql.org/download/postgresql-42.6.0.jar"
        DB_DRIVER_NAME="postgres-connector.jar" ;;
    *)
        DB_DRIVER_CLASS=""; DB_DRIVER_URL=""; DB_DRIVER_NAME="" ;;
esac

export DB_DRIVER_CLASS
export DB_DRIVER_PATH="/tmp/$DB_DRIVER_NAME"

# --- Aguardar banco de dados ---
echo "Aguardando banco ($DB_HOST:$DB_PORT)..."
until timeout 1 bash -c "cat < /dev/null > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; do sleep 2; done
echo "Banco disponível."

# --- Driver JDBC ---
mkdir -p /tmp/fluig-installer
[ ! -f "$DB_DRIVER_PATH" ] && [ -n "$DB_DRIVER_URL" ] && \
    curl -L -s -o "$DB_DRIVER_PATH" "$DB_DRIVER_URL"

# FLUIG_UPDATE controla o modo de instalação:
#   false   → boot normal, sem instalação
#   install → apaga o volume e reinstala do zero (is_new_install=true)
#   update  → mantém o volume e aplica patch (is_new_install=false)
XML_CONFIG="$FLUIG_INSTALL_PATH/appserver/standalone/configuration/standalone.xml"
export IS_NEW_INSTALL=true
export DB_CREATE_SCHEMA=true

if [ ! -f "$XML_CONFIG" ] || [ "$FLUIG_UPDATE" = "install" ]; then
    echo "Modo: instalação limpa..."
    # O instalador extrai tudo a partir do diretório corrente (/installer/package)
    # para $FLUIG_INSTALL_PATH, que deve estar vazio antes de rodar.
    find "$FLUIG_INSTALL_PATH" -mindepth 1 -delete
elif [ "$FLUIG_UPDATE" = "update" ]; then
    echo "Modo: atualização/patch (volume preservado)..."
    export IS_NEW_INSTALL=false
    export DB_CREATE_SCHEMA=false
else
    echo "Fluig já instalado, pulando instalação."
fi

if [ ! -f "$XML_CONFIG" ] || [ "$FLUIG_UPDATE" = "install" ] || [ "$FLUIG_UPDATE" = "update" ]; then
    eval "echo \"$(cat /installer/scripts/install.conf.template)\"" > /tmp/fluig-installer/install.conf
    # O instalador deve ser executado a partir do seu diretório:
    # ele busca o JDK em ./jdk-64 relativo ao CWD.
    cd /installer/package
    JAVA_BIN=$(find /installer/package/jdk-64/bin -name java)
    INSTALLER_JAR=$(find /installer/package -name "fluig-installer.jar")
    $JAVA_BIN -Xmx512m -DINSTALL_PATH="$FLUIG_INSTALL_PATH" \
        -cp "$INSTALLER_JAR" com.fluig.install.ExecuteInstall \
        /tmp/fluig-installer/install.conf
    echo "Instalação/atualização concluída."
fi

# --- Patches no standalone.xml ---
# Aplicados em todo boot para garantir consistência após reinstalações.
if [ -f "$XML_CONFIG" ]; then
    SMTP_SERVER=${EMAIL_SERVER:-"smtp.gmail.com"}
    SMTP_PORT=${EMAIL_PORT:-"587"}
    [[ ! "$SMTP_PORT" =~ ^[0-9]+$ ]] && SMTP_PORT="587"

    sed -i \
        's|<inet-address[^>]*/>|<any-address/>|g;
         s|socket-binding name="http" port="[^"]*"|socket-binding name="http" port="8080"|g;
         s|__email_smtpServer__|'"$SMTP_SERVER"'|g;
         s|__email_smtpPort__|'"$SMTP_PORT"'|g' \
        "$XML_CONFIG"
fi

chown -R fluig:fluig "$FLUIG_INSTALL_PATH"

# --- Solr (Indexer) ---
# Solr 9.x bloqueia dataDirs fora do SOLR_HOME via SecurityManager.
# O instalador cria /etc/default/fluig_Indexer.in.sh, mas sobrescrevemos
# com as flags necessárias para o Fluig funcionar.
if [ "$INSTALL_SOLR" = "true" ] && [ -f "$FLUIG_INSTALL_PATH/solr/bin/solr" ]; then
    export JAVA_HOME="$FLUIG_INSTALL_PATH/jdk-64"
    export PATH="$JAVA_HOME/bin:$PATH"

    cat > /etc/default/fluig_Indexer.in.sh << 'EOF'
SOLR_SECURITY_MANAGER_ENABLED=false
SOLR_OPTS="$SOLR_OPTS -Dsolr.allowPaths=*"
EOF

    "$FLUIG_INSTALL_PATH/solr/bin/solr" start -p 8983 -force 2>&1 || true

    for i in $(seq 1 30); do
        "$FLUIG_INSTALL_PATH/solr/bin/solr" status 2>/dev/null | grep -q "running" && { echo "Solr pronto."; break; }
        sleep 2
    done

    # Cria o core '0' se não existir — o Fluig usa dataDir fora do SOLR_HOME,
    # por isso o core não é criado automaticamente pelo Solr.
    SOLR_DATA_DIR="$FLUIG_INSTALL_PATH/repository/wcmdir/wcm/tenants/wcm/index"
    CORES=$(curl -s 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json')
    if ! echo "$CORES" | grep -q '"0":{'; then
        mkdir -p "$SOLR_DATA_DIR" && chown -R fluig:fluig "$SOLR_DATA_DIR"
        curl -s "http://localhost:8983/solr/admin/cores?action=CREATE&name=0&configSet=fluig&dataDir=${SOLR_DATA_DIR}" > /dev/null
        echo "Core Solr '0' criado."
    fi
fi

# --- JBoss/WildFly ---
echo "Iniciando JBoss..."
su - fluig -c "cd $FLUIG_INSTALL_PATH/appserver/bin && nohup ./standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 >> /tmp/jboss.log 2>&1 &"

for i in $(seq 1 60); do
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/localhost/8080" 2>/dev/null && { echo "JBoss pronto."; break; }
    sleep 5
done

# --- Node.js Realtime ---
# chatPort (7070) = socket.io/WebSocket. O instalador grava 8888 no package.json,
# mas essa porta é usada pelo Express (HTTP). O WebSocket precisa de uma porta separada.
if [ "$INSTALL_NODE" = "true" ] && [ -f "$FLUIG_INSTALL_PATH/node/bin/node" ]; then
    FLUIG_RT_PKG="$FLUIG_INSTALL_PATH/node/bin/fluig.rt/package.json"
    NODE_LOG="$FLUIG_INSTALL_PATH/node/bin/fluig.rt/logs/server.log"
    mkdir -p "$(dirname "$NODE_LOG")"
    sed -i 's/"chatPort": 8888/"chatPort": 7070/' "$FLUIG_RT_PKG"
    > "$NODE_LOG"
    su - fluig -c "nohup $FLUIG_INSTALL_PATH/node/bin/node $FLUIG_INSTALL_PATH/node/bin/fluig.rt >> $NODE_LOG 2>&1 &"
    echo "Node.js Realtime iniciado."
fi

echo "Todos os serviços iniciados."
tail -f /tmp/jboss.log "$FLUIG_INSTALL_PATH/appserver/standalone/log/server.log" 2>/dev/null
