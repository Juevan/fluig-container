#!/bin/bash

patch_xml() {
    XML_CONFIG="$FLUIG_INSTALL_PATH/appserver/standalone/configuration/standalone.xml"
    # --- Patches no standalone.xml ---
    # Aplicados em todo boot para garantir consistência após reinstalações.
    if [ -f "$XML_CONFIG" ]; then
        SMTP_SERVER=${EMAIL_HOST:-"mailpit"}
        SMTP_PORT=${EMAIL_PORT:-"1025"}
        [[ ! "$SMTP_PORT" =~ ^[0-9]+$ ]] && SMTP_PORT="1025"

        sed -i \
            's|<inet-address[^>]*/>|<any-address/>|g;
              s|socket-binding name="http" port="[^"]*"|socket-binding name="http" port="8080"|g;
              s|__email_smtpServer__|'"$SMTP_SERVER"'|g;
              s|__email_smtpPort__|'"$SMTP_PORT"'|g' \
            "$XML_CONFIG"
    fi

    chown -R fluig:fluig "$FLUIG_INSTALL_PATH"
}
