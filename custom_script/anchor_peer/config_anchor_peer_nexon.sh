#!/bin/bash

# Using binaries execution
export PATH=$PATH:${PWD}/bin

###############
#### Nexon ####
###############

## Environment variables
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/gamersgacha.com/orderers/Gamers-Gacha.gamersgacha.com/msp/tlscacerts/tlsca.gamersgacha.com-cert.pem

### For Nexon
export CORE_PEER_LOCALMSPID=NexonMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nexon.example.com/peers/peer0.nexon.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nexon.example.com/users/Admin@nexon.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

CHANNEL_NAME=$1
HOST="peer0.nexon.example.com"
PORT="7051"

## Fetch Config block
echo "Step 1. Fetch Config block"
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/gamersgacha.com/orderers/Gamers-Gacha.gamersgacha.com/msp/tlscacerts/tlsca.gamersgacha.com-cert.pem

if [ ! -d "./anchor" ]
then
    mkdir anchor
fi
cd anchor

peer channel fetch config config_block.pb \
  -o localhost:7050 \
  --ordererTLSHostnameOverride Gamers-Gacha.gamersgacha.com \
  -c "$CHANNEL_NAME" \
  --tls \
  --cafile "$ORDERER_CA"

## Decoding Config block
echo "Step 2. Decoding Config block"
configtxlator proto_decode \
  --input config_block.pb \
  --type common.Block \
  | jq .data.data[0].payload.data.config \
  > ${CORE_PEER_LOCALMSPID}config.json

## Modify configuration
echo "Step 3. Modify configuration"
jq '.channel_group.groups.Application.groups.'$CORE_PEER_LOCALMSPID'.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "'$HOST'","port": "'$PORT'"}]},"version": "0"}}' ${CORE_PEER_LOCALMSPID}config.json \
  > ${CORE_PEER_LOCALMSPID}modified_config.json

## Create Config update
echo "Step 4. Create Config update"
configtxlator proto_encode \
  --input ${CORE_PEER_LOCALMSPID}config.json \
  --type common.Config \
  > original_config.pb

configtxlator proto_encode \
  --input ${CORE_PEER_LOCALMSPID}modified_config.json \
  --type common.Config \
  > modified_config.pb

configtxlator compute_update \
  --channel_id $CHANNEL_NAME \
  --original original_config.pb \
  --updated modified_config.pb \
  > config_update.pb

configtxlator proto_decode \
  --input config_update.pb \
  --type common.ConfigUpdate \
  > config_update.json

echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' \
  | jq . \
  > config_update_in_envelope.json

configtxlator proto_encode \
  --input config_update_in_envelope.json \
  --type common.Envelope \
  > ${CORE_PEER_LOCALMSPID}anchors.tx 

## Sign
echo "Step 5. Sign"
peer channel signconfigtx -f ${CORE_PEER_LOCALMSPID}anchors.tx

## Update
echo "Step 6. Update"
peer channel update \
  -o localhost:7050 \
  --ordererTLSHostnameOverride Gamers-gacha.gamersgacha.com \
  -c $CHANNEL_NAME \
  -f ${CORE_PEER_LOCALMSPID}anchors.tx \
  --tls \
  --cafile $ORDERER_CA