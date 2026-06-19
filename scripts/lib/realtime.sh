#!/bin/bash

start_realtime() {
    # --- Node.js Realtime ---
    # chatPort (7070) = socket.io/WebSocket. O instalador grava 8888 no package.json,
    # mas essa porta é usada pelo Express (HTTP). O WebSocket precisa de uma porta separada.
    if [ "$INSTALL_NODE" = "true" ] && [ -f "$FLUIG_INSTALL_PATH/node/bin/node" ]; then
        local rt_dir="$FLUIG_INSTALL_PATH/node/bin/fluig.rt"
        local node_log="$rt_dir/logs/server.log"

        mkdir -p "$(dirname "$node_log")"
        sed -i 's/"chatPort": 8888/"chatPort": 7070/' "$rt_dir/package.json"
        > "$node_log"

        su - fluig -c "nohup $FLUIG_INSTALL_PATH/node/bin/node $rt_dir >> $node_log 2>&1 &"
        echo "Node.js Realtime iniciado."
    fi
}
