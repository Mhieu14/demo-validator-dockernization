#!/bin/bash

##### CONFIGURATION ###
export CURRENT_FOLDER=$(pwd)
export NODE_HOME=/workspace/.gaiad
export CHAIN_ID=darchub
export NODE_MONIKER="test-vchain"
export BINARY=gaiad
export PERSISTENT_PEERS="159.223.35.6:26656"
export GENESIS_JSON_URL=https://cdn.discordapp.com/attachments/1025335421607104522/1052894817887191080/genesis.json
echo "Updating apt-get..."
apt-get update -y

echo "Getting essentials..."
apt-get install -y make gcc

echo "Getting gaia..."
git clone -b v7.1.0 https://github.com/cosmos/gaia.git

echo "cd into gaia..."
cd gaia

echo "building gaia..."
make build

echo "gaia version:"
build/gaiad version
cp build/gaiad /bin/gaiad

cd ..
export PATH="/bin/gaiad:$PATH"

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

echo "init gaiad file config"
/bin/gaiad init $NODE_MONIKER --home /default_config/ --chain-id=darchub -o
rm -r -f /default_config/data/
wget -O /default_config/config/genesis.json ${GENESIS_JSON_URL}
sed -i '/\[instrumentation\]/{:a;n;/prometheus/s/false/true/;Ta}' /default_config/config/config.toml
sed -i 's/pruning = \x22default\x22/pruning = \x22nothing\x22/' /default_config/config/app.toml
sed -i '/\[rpc\]/,+3 s/laddr = \"tcp:\/\/127.0.0.1:26657\"/laddr = \"tcp:\/\/0.0.0.0:26657\"/' /default_config/config/config.toml
sed -i '/\[grpc\]/,+3 s/enable = false/enable = true/;/\[api\]/,+3 s/enable = false/enable = true/;/\[rosetta\]/,+3 s/enable = true/enable = false/' /default_config/config/app.toml
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PERSISTENT_PEERS\"/" /default_config/config/config.toml
