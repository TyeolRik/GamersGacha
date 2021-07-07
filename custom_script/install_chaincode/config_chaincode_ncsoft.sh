#!/bin/bash/

# Step 8-2. Install -> Approve -> Commit : Nexon

# Using binaries execution
export PATH=$PATH:${PWD}/bin

################
#### NCsoft ####
################

## Environment variables
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/gamersgacha.com/orderers/Gamers-Gacha.gamersgacha.com/msp/tlscacerts/tlsca.gamersgacha.com-cert.pem

### For NCsoft
export CORE_PEER_LOCALMSPID=NCsoftMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/ncsoft.example.com/peers/peer0.ncsoft.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/ncsoft.example.com/users/Admin@ncsoft.example.com/msp
export CORE_PEER_ADDRESS=localhost:11051

CHAINCODE_NAME=$1
Hostname=$2
CHANNEL_NAME=$3
CHAINCODE_VERSION=$4

# 8-2. Install
if peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz ; then
    echo "Step 2-1. Installing Chaincode SUCCESS"
    ## Check Nexon and Save Package ID
    echo "Step 2-2. Check Nexon and Save Package ID"
    : << END
    export PACKAGE_ID=$(peer lifecycle chaincode queryinstalled --output json \
                        | jq -r ".installed_chaincodes | .[] | select(.label==\"$CHAINCODE_NAME\") | .package_id" \
                        | tr -d "${CHAINCODE_NAME}: ")
END
    export PACKAGE_ID=$(peer lifecycle chaincode queryinstalled --output json \
                        | jq -r ".installed_chaincodes | .[] | select(.label==\"$CHAINCODE_NAME\") | .package_id")
    echo $PACKAGE_ID
else
    echo "Failed to install Chaincode successfully!"
    exit 1
fi

# 8-3. Approve
echo "Step 8-3-1. Approve"
peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride $Hostname \
    --tls \
    --cafile $ORDERER_CA \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --package-id $PACKAGE_ID \
    --sequence 1 NA NA NA

# Check
echo "Step 8-3-2. Approve Check"
peer lifecycle chaincode checkcommitreadiness \
    --channelID $CHANNEL_NAME \
    --name $CHAINCODE_NAME \
    --version $CHAINCODE_VERSION \
    --sequence 1 NA NA NA NA

