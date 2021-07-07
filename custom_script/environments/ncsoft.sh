#!/bin/bash

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