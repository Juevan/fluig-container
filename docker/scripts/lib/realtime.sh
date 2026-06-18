#!/bin/bash

start_realtime() {
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
}
