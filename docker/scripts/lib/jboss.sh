#!/bin/bash

start_jboss() {
    # --- JBoss/WildFly ---
    echo "Iniciando JBoss..."
    su - fluig -c "cd $FLUIG_INSTALL_PATH/appserver/bin && nohup ./standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 >> /tmp/jboss.log 2>&1 &"

    for i in $(seq 1 60); do
        timeout 1 bash -c "cat < /dev/null > /dev/tcp/localhost/8080" 2>/dev/null && { echo "JBoss pronto."; break; }
        sleep 5
    done
}
