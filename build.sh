#!/bin/bash

###################################
# This script is for fast testing #
###################################

Hostname="Gamers-Gacha.gamersgacha.com"
export CHANNEL_NAME="test-net1"
export ORDERER_ADDRESS="Gamers-Gacha.gamersgacha.com:7050"
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/gamersgacha.com/orderers/Gamers-Gacha.gamersgacha.com/msp/tlscacerts/tlsca.gamersgacha.com-cert.pem

CHAINCODE_NAME="randomtest"
CHAINCODE_VERSION=1

# Remove Docker containers
docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q) && echo "Docker Container removing SUCCESS"
docker volume prune --force && echo "Docker Volume Pruning SUCCESS"

# Remove certificates if it already exists
rm -rf ./channel-artifacts
rm -rf ./organizations/ordererOrganizations
rm -rf ./organizations/peerOrganizations
rm -rf ./anchor
rm -rf ./${CHAINCODE_NAME}.tar.gz


if [ ! -d "./organizations/cryptogen" ] ; then
    mkdir -p ./organizations/cryptogen
fi

if [ ! -d "./configtx " ] ; then
    mkdir -p ./configtx
fi

if [ ! -d "./docker " ] ; then
    mkdir -p ./docker
fi

export PATH=$PATH:${PWD}/bin

# Step 2. Generate Key
echo "Step 2. Generate Key"
# Write Crypto-config files (in ./organizations/cryptogen/)
# After Writing
cryptogen generate \
    --config=./organizations/cryptogen/crypto-config-nexon.yaml \
    --output="organizations"
cryptogen generate \
    --config=./organizations/cryptogen/crypto-config-netmarble.yaml \
    --output="organizations"
cryptogen generate \
    --config=./organizations/cryptogen/crypto-config-ncsoft.yaml \
    --output="organizations"
cryptogen generate \
    --config=./organizations/cryptogen/crypto-config-orderer.yaml \
    --output="organizations"

# Step 3. Generate Genesis file
echo "Step 3. Generate Genesis file"
# Write configtx file (./configtx/configtx.yaml)
# After Writing
configtxgen \
    -profile ThreeOrgsOrdererGenesis \
    -channelID system-channel \
    -outputBlock ./system-genesis-block/genesis.block \
    -configPath ./configtx

# Step 4. Start Network
echo "Step 4. Start Network"
# Write ./docker/docker-compose.yaml
# After Writing
cd ./docker
COMPOSE_PROJECT_NAME=net docker-compose up -d
cd ..
# Check Containers
docker ps -a

# Step 5. Create Channel
echo "Step 5. Create Channel"
export FABRIC_CFG_PATH=${PWD}/configtx

# Step 5-1. Create Channel Genesis Block
echo "Step 5-1. Create Channel Genesis Block"
configtxgen \
    -profile ThreeOrgsChannel \
    -outputCreateChannelTx ./channel-artifacts/${CHANNEL_NAME}.tx \
    -channelID ${CHANNEL_NAME}

export CORE_PEER_TLS_ENABLED=true
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_LOCALMSPID=NexonMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nexon.example.com/peers/peer0.nexon.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nexon.example.com/users/Admin@nexon.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Step 5-2. Create Channel
echo "Step 5-2. Create Channel"
# Poll in case the raft leader is not set yet
export rc=1
export COUNTER=1
export DELAY=3
export MAX_RETRY=5
export ORDERER_ADMIN_TLS_SIGN_CERT=./organizations/ordererOrganizations/gamersgacha.com/orderers/Gamers-Gacha.gamersgacha.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=./organizations/ordererOrganizations/gamersgacha.com/orderers/Gamers-Gacha.gamersgacha.com/tls/server.key

while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
	sleep $DELAY
	set -x
    : << END
	osnadmin channel join \
            --channelID $CHANNEL_NAME \
            --config-block ./channel-artifacts/${CHANNEL_NAME}.block \
            -o ${ORDERER_ADDRESS} \
            --ca-file "$ORDERER_CA" \
            --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" \
            --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
END
    peer channel create \
    -o localhost:7050 \
    -c $CHANNEL_NAME \
    --ordererTLSHostnameOverride $Hostname \
    -f ./channel-artifacts/$CHANNEL_NAME.tx \
    --outputBlock ./channel-artifacts/$CHANNEL_NAME.block \
    --tls \
    --cafile $ORDERER_CA

	res=$?
    echo $res
	{ set +x; } 2>/dev/null
	let rc=$res
	COUNTER=$(expr $COUNTER + 1)
done

if [ $res -ne 0 ] ; then
    echo "ERROR :: Channel creation failed!!"
    exit 1
fi

# Step 6. Join Channels
echo "Step 6. Join Channels"
echo "Step 6-1. Join Nexon"
bash ./custom_script/join_channel/join_channel_nexon.sh $CHANNEL_NAME
echo "Step 6-2. Join Netmarble"
bash ./custom_script/join_channel/join_channel_netmarble.sh $CHANNEL_NAME
echo "Step 6-3. Join NCsoft"
bash ./custom_script/join_channel/join_channel_ncsoft.sh $CHANNEL_NAME

# Step 7. Configuare Anchor Peer
echo "Step 7. Configuare Anchor Peer"
echo "Step 7-1. Anchor Peer - Nexon"
bash ./custom_script/anchor_peer/config_anchor_peer_nexon.sh $CHANNEL_NAME
echo "Step 7-2. Anchor Peer - Netmarble"
bash ./custom_script/anchor_peer/config_anchor_peer_netmarble.sh $CHANNEL_NAME
echo "Step 7-3. Anchor Peer - NCsoft"
bash ./custom_script/anchor_peer/config_anchor_peer_ncsoft.sh $CHANNEL_NAME

# Step 8. Chaincode
echo "Step 8. Chaincode"
echo "Step 8-1. Package"
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz \
    --path ./"${CHAINCODE_NAME}"/ \
    --lang golang \
    --label "$CHAINCODE_NAME"

echo "Step 8-2,3. Install -> Approve : Nexon"
bash ./custom_script/install_chaincode/config_chaincode_nexon.sh "$CHAINCODE_NAME" "$Hostname" "$CHANNEL_NAME" "$CHAINCODE_VERSION"
echo "Step 8-2,3. Install -> Approve : Netmarble"
bash ./custom_script/install_chaincode/config_chaincode_netmarble.sh "$CHAINCODE_NAME" "$Hostname" "$CHANNEL_NAME" "$CHAINCODE_VERSION"
echo "Step 8-2,3. Install -> Approve : NCsoft"
bash ./custom_script/install_chaincode/config_chaincode_ncsoft.sh "$CHAINCODE_NAME" "$Hostname" "$CHANNEL_NAME" "$CHAINCODE_VERSION"

echo "Step 8-4. Commit"
# Commit definition
echo "Step 8-4-1. Commit definition"
peer lifecycle chaincode commit \
    -o localhost:7050 \
    --ordererTLSHostnameOverride $Hostname \
    --tls \
    --cafile "$ORDERER_CA" \
    --channelID $CHANNEL_NAME \
    --name ${CHAINCODE_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/nexon.example.com/peers/peer0.nexon.example.com/tls/ca.crt \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/netmarble.example.com/peers/peer0.netmarble.example.com/tls/ca.crt \
    --peerAddresses localhost:11051 \
    --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/ncsoft.example.com/peers/peer0.ncsoft.example.com/tls/ca.crt \
    --version ${CHAINCODE_VERSION} \
    --sequence 1 NA NA NA

source custom_script/environments/nexon.sh
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CHAINCODE_NAME}
source custom_script/environments/netmarble.sh
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CHAINCODE_NAME}
source custom_script/environments/ncsoft.sh
peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CHAINCODE_NAME}