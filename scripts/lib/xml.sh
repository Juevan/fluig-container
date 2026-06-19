#!/bin/bash

patch_xml() {
    XML_CONFIG="$FLUIG_INSTALL_PATH/appserver/standalone/configuration/standalone.xml"
    # --- Patches no standalone.xml ---
    # Aplicados em todo boot para garantir consistência após reinstalações.
    if [ -f "$XML_CONFIG" ]; then
        local smtp_server=${EMAIL_HOST:-"mailpit"}
        local smtp_port=${EMAIL_PORT:-"1025"}
        [[ ! "$smtp_port" =~ ^[0-9]+$ ]] && smtp_port="1025"

        sed -i \
            's|<inet-address[^>]*/>|<any-address/>|g;
              s|socket-binding name="http" port="[^"]*"|socket-binding name="http" port="8080"|g;
              s|__email_smtpServer__|'"$smtp_server"'|g;
              s|__email_smtpPort__|'"$smtp_port"'|g' \
            "$XML_CONFIG"
    fi

    chown -R fluig:fluig "$FLUIG_INSTALL_PATH"
}
