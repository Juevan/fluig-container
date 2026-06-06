#!/bin/bash

start_solr() {
    # --- Solr (Indexer) ---
    # Solr 9.x bloqueia dataDirs fora do SOLR_HOME via SecurityManager.
    # O instalador cria /etc/default/fluig_Indexer.in.sh, mas sobrescrevemos
    # com as flags necessárias para o Fluig funcionar.
    if [ "$ENABLE_SOLR" = "true" ] && [ -f "$FLUIG_INSTALL_PATH/solr/bin/solr" ]; then
        export JAVA_HOME="$FLUIG_INSTALL_PATH/jdk-64"
        export PATH="$JAVA_HOME/bin:$PATH"

        cat > /etc/default/fluig_Indexer.in.sh << 'EOF'
SOLR_SECURITY_MANAGER_ENABLED=false
SOLR_OPTS="$SOLR_OPTS -Dsolr.allowPaths=*"
EOF

        chmod 644 /etc/default/fluig_Indexer.in.sh

        su - fluig -c "export JAVA_HOME=\"$FLUIG_INSTALL_PATH/jdk-64\" && export PATH=\"\$JAVA_HOME/bin:\$PATH\" && \"$FLUIG_INSTALL_PATH/solr/bin/solr\" start -p 8983 2>&1" || true

        for i in $(seq 1 30); do
            su - fluig -c "export JAVA_HOME=\"$FLUIG_INSTALL_PATH/jdk-64\" && export PATH=\"\$JAVA_HOME/bin:\$PATH\" && \"$FLUIG_INSTALL_PATH/solr/bin/solr\" status" 2>/dev/null | grep -q "running" && { echo "Solr pronto."; break; }
            sleep 2
        done

        # Cria o core '0' se não existir — o Fluig usa dataDir fora do SOLR_HOME,
        # por isso o core não é criado automaticamente pelo Solr.
        SOLR_DATA_DIR="$FLUIG_INSTALL_PATH/repository/wcmdir/wcm/tenants/wcm/index"
        CORES=$(curl -s 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json')
        if ! echo "$CORES" | grep -q '"0":{'; then
            mkdir -p "$SOLR_DATA_DIR" && chown -R fluig:fluig "$SOLR_DATA_DIR"
            mkdir -p "$FLUIG_INSTALL_PATH/solr/server/solr/0"
            cp -rf "$FLUIG_INSTALL_PATH/solr/server/solr/configsets/fluig/conf" "$FLUIG_INSTALL_PATH/solr/server/solr/0/"
            chown -R fluig:fluig "$FLUIG_INSTALL_PATH/solr/server/solr/0"
            curl -s "http://localhost:8983/solr/admin/cores?action=CREATE&name=0&configSet=fluig&dataDir=${SOLR_DATA_DIR}" > /dev/null
            echo "Core Solr '0' criado."
        fi
    fi
}
