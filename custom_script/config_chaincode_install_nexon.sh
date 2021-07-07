#!/bin/bash

#######################################################
#                 Chaincode Lifecycle                 #
#                                                     #
# Fabric 2.x: Package -> Install -> Approve -> Commit #
#######################################################

# Hostname
HOSTNAME="Gamers-Gacha.gamersgacha.com"
CHANNEL_NAME="mychannel"


# Change directory to base folder
cd ..

# Using binaries execution
export PATH=$PATH:${PWD}/bin

# 0. Setting Environment Variables
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/gamersgacha.com/orderers/Gamers-Gacha.gamersgacha.com/msp/tlscacerts/tlsca.gamersgacha.com-cert.pem

## For Nexon
export CORE_PEER_LOCALMSPID=NexonMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nexon.example.com/peers/peer0.nexon.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nexon.example.com/users/Admin@nexon.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

LABEL="randomtest_version_1"

# 1. Package
echo "Step 1. Package"
peer lifecycle chaincode package random-chaincode.tar.gz \
  --path ./random-test/ \
  --lang golang \
  --label $LABEL


# 2. Install
echo "Step 2. Install"
## 2-1. Installing Chaincode
echo "Step 2-1. Installing Chaincode"
: <<'END'
if peer lifecycle chaincode install random-chaincode.tar.gz ; then
    echo "Step 2-1. Installing Chaincode SUCCESS"
    ## 2-2. Check Nexon and Save Package ID
    echo "Step 2-2. Check Nexon and Save Package ID"
    export PACKAGE_ID=$(peer lifecycle chaincode queryinstalled --output json \
                        | jq -r '.installed_chaincodes | .[] | select(.label=="${LABEL}") | .package_id' \
                        | tr -d "${LABEL}: ")
    echo $PACKAGE_ID
else
    echo "Failed to install Chaincode successfully!"
    exit 1
fi
END
export PACKAGE_ID=$(peer lifecycle chaincode queryinstalled --output json \
                    | jq -r ".installed_chaincodes | .[] | select(.label==\"$LABEL\") | .package_id" \
                    | tr -d "${LABEL}: ")

# 3. Approve
## 3.1 Try to approve
echo "Step 3. Approve"
echo "Step 3-1. Approve"
peer lifecycle chaincode approveformyorg \
  -o localhost:7050 \
  --ordererTLSHostnameOverride $HOSTNAME \
  --tls \
  --cafile $ORDERER_CA \
  --channelID $CHANNEL_NAME \
  --name $LABEL \
  --version 1 \
  --package-id $PACKAGE_ID \
  --sequence 1 NA NA NA
## 3-2. Check whether approved
echo "Step 3-2. Check whether approved"
peer lifecycle chaincode checkcommitreadiness \
    --channelID $CHANNEL_NAME \
    --name $LABEL \
    --version 1 \
    --sequence 1 NA NA NA NA
