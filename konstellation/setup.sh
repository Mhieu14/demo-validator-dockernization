##### CONFIGURATION ###
export CURRENT_FOLDER=$(pwd)
export NODE_HOME=/workspace/.knstld
export CHAIN_ID=darchub
export NODE_MONIKER="test-knstld"
export BINARY=knstld


echo "Updating apt-get..."
apt-get update -y

echo "Getting essentials..."
apt-get install -y make gcc


echo "Getting konstellation..."
git clone -b v0.5.0 https://github.com/konstellation/konstellation

echo "cd into konstellation..."
cd konstellation


echo "building konstellation..."
make build
# Check konstellation version
build/knstld version

cp build/knstld /bin/knstld

cd ..


export PATH="/bin/knstld:$PATH"


echo "Install cosmovisor"


go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

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
mkdir -p $NODE_HOME/cosmovisor/upgrades

cp /bin/$BINARY $NODE_HOME/cosmovisor/genesis/bin


go install github.com/MinseokOh/toml-cli@latest