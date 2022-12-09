#!/bin/bash

##### CONFIGURATION ###
export CURRENT_FOLDER=$(pwd)
export NODE_HOME=/workspace/.knstld
export CHAIN_ID=darchub
export NODE_MONIKER="test-knstld"
export BINARY=knstld
export PERSISTENT_PEERS="00f7f4506d84f9d1458201946e1194564b444ce0@node14.konstellation.tech:26656,06fed4bbe81ead6073a7254e860331179af74f4c@node3.konstellation.tech:26656,0f4eef8db37ec7ef9f6d3324689db2847ee8f795@node10.konstellation.tech:26656,1c9aff1ea9d1cafd584aa61a70582e7c4b0c8675@node5.konstellation.tech:26656,7e8119050ecb80450ad476b50423b9230c10c8d0@node11.konstellation.tech:26656,a32dda75cf5ffe4ab0ff9a0969e525807e01f2e5@node2.konstellation.tech:26656,d4a713a657883cca49d71b1b2cab4ab5e94b0843@node4.konstellation.tech:26656,dbb7589202f6c751f2b93c6bbcd0e660676ab91c@node12.konstellation.tech:26656,f2c2ebec24507d54fea88976e9f93f0fbfa0d6d0@node13.konstellation.tech:26656"
export GENESIS_JSON_URL=https://raw.githubusercontent.com/Konstellation/konstellation/master/config/genesis.json
echo "Updating apt-get..."
apt-get update -y

echo "Getting essentials..."
apt-get install -y make gcc

echo "Getting konstellation..."
git clone -b v0.6.2 https://github.com/konstellation/konstellation

echo "cd into konstellation..."
cd konstellation

echo "building konstellation..."
make build

echo "konstellation version:"
build/knstld version
cp build/knstld /bin/knstld

cd ..
export PATH="/bin/knstld:$PATH"

echo "Install cosmovisor"
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

echo "cosmovisor version:"
cosmovisor version

export DAEMON_HOME=$NODE_HOME
export DAEMON_NAME=$BINARY
export DAEMON_ALLOW_DOWNLOAD_BINARIES=true

echo "# Setup Cosmovisor" >> ~/.profile
echo "export DAEMON_HOME=$NODE_HOME" >> ~/.profile
echo "export DAEMON_NAME=$BINARY" >> ~/.profile
echo "DAEMON_ALLOW_DOWNLOAD_BINARIES=true" >> ~/.profile
source ~/.profile

mkdir -p $NODE_HOME
mkdir -p $NODE_HOME/cosmovisor
mkdir -p $NODE_HOME/cosmovisor/genesis
mkdir -p $NODE_HOME/cosmovisor/genesis/bin
mkdir -p $NODE_HOME/cosmovisor/upgrades/v0.45/bin

cp /bin/$BINARY $NODE_HOME/cosmovisor/upgrades/v0.45/bin
cp /bin/$BINARY $NODE_HOME/cosmovisor/genesis/bin

go install github.com/MinseokOh/toml-cli@latest

mkdir /default_config

echo "init knstld file config"
/bin/knstld init $NODE_MONIKER --home /default_config/ --chain-id=darchub -o
rm -r -f /default_config/data/
wget -O /default_config/config/genesis.json ${GENESIS_JSON_URL}
sed -i '/\[instrumentation\]/{:a;n;/prometheus/s/false/true/;Ta}' /default_config/config/config.toml
sed -i 's/pruning = \x22default\x22/pruning = \x22nothing\x22/' /default_config/config/app.toml
sed -i '/\[rpc\]/,+3 s/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/' /default_config/config/config.toml
sed -i '/\[grpc\]/,+3 s/enable = false/enable = true/;/\[api\]/,+3 s/enable = false/enable = true/;/\[rosetta\]/,+3 s/enable = true/enable = false/' /default_config/config/app.toml
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PERSISTENT_PEERS\"/" /default_config/config/config.toml
