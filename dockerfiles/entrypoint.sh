#!/bin/bash
set -e

MCL_DIR="/home/mclminer/.komodo/MCL"
MCL_CONF="${MCL_DIR}/MCL.conf"
STRATUM_PATH="/home/mclminer/yiimp-stratum-equihash"
DB_CPP="${STRATUM_PATH}/db.cpp"

chown -R mclminer:usergroup "$MCL_DIR"
if [ ! -d "$MCL_DIR" ]; then
  echo "==> Creating directory $MCL_DIR ..."
  mkdir -p "$MCL_DIR"
fi

if [ ! -f "$MCL_CONF" ]; then
  echo "==> Generating $MCL_CONF ..."
  cat > "$MCL_CONF" <<EOF
rpcuser=${RPC_USER}
rpcpassword=${RPC_PASS}
rpcport=33825
server=1
txindex=1
rpcworkqueue=256
rpcallowip=127.0.0.1
rpcbind=127.0.0.1
EOF
else
  echo "==> Updating $MCL_CONF with new RPC values ..."
  sed -i "s/^rpcuser=.*/rpcuser=${RPC_USER}/" "$MCL_CONF"
  sed -i "s/^rpcpassword=.*/rpcpassword=${RPC_PASS}/" "$MCL_CONF"
fi


echo "==> Updating db.cpp with environment variables ..."

# rpc.host satırı (// [2] rpc.host)
if [ -n "$RPC_HOST" ]; then
  sed -i "s|.*// \[2\] rpc.host.*|            \"${RPC_HOST}\", // [2] rpc.host|" "$DB_CPP"
fi
sed -i "s|.*// \[4\] rpc.user.*|            \"${RPC_USER}\", // [4] rpc.user|" "$DB_CPP"
sed -i "s|.*// \[5\] rpc.pass.*|            \"${RPC_PASS}\", // [5] rpc.pass|" "$DB_CPP"
sed -i "s|.*// \[7\] wallet.*|            \"${WALLET}\", // [7] wallet|" "$DB_CPP"


# Start fetch-params.sh
/home/mclminer/fetch-params.sh
# Start MCL Node
echo "==> Starting MarmaraChain daemon ..."
/usr/local/bin/marmarad -pubkey=${PUBKEY} > /home/mclminer/marmarad.log 2>&1 &
sleep 10

# execute CMD or command from docker-compose
exec "$@"