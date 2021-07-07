#!/bin/bash

# Using binaries execution
export PATH=$PATH:${PWD}/bin

# 0. Setting Environment Variables
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true

## For Nexon
export CORE_PEER_LOCALMSPID=NexonMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nexon.example.com/peers/peer0.nexon.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nexon.example.com/users/Admin@nexon.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Join Channel
if [ $# -ne 1 ] ; then
    peer channel join -b ./channel-artifacts/mychannel.block
else
    peer channel join -b ./channel-artifacts/$1.block
fi

# Check whether Joined
peer channel list