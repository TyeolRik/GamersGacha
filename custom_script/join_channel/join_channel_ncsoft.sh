#!/bin/bash

# Using binaries execution
export PATH=$PATH:${PWD}/bin

## Environment variables
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true

### For NCsoft
export CORE_PEER_LOCALMSPID=NCsoftMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/ncsoft.example.com/peers/peer0.ncsoft.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/ncsoft.example.com/users/Admin@ncsoft.example.com/msp
export CORE_PEER_ADDRESS=localhost:11051

# Join Channel
if [ $# -ne 1 ] ; then
    peer channel join -b ./channel-artifacts/mychannel.block
else
    peer channel join -b ./channel-artifacts/$1.block
fi

# Check whether Joined
peer channel list