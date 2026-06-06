#!/bin/bash

install_fluig() {
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
        # Resolve variables using envsubst
        envsubst < /installer/scripts/install.conf.template > /tmp/fluig-installer/install.conf

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
}
