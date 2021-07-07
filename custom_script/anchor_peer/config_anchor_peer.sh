#!/bin/bash/

# Using binaries execution
export PATH=$PATH:${PWD}/bin

###############
#### Nexon ####
###############

## Environment variables
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/gamersgacha.com/orderers/Gamers-Gacha.gamersgacha.com/msp/tlscacerts/tlsca.gamersgacha.com-cert.pem

### For Netmarble
export CORE_PEER_LOCALMSPID=NetmarbleMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/netmarble.example.com/peers/peer0.netmarble.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/netmarble.example.com/users/Admin@netmarble.example.com/msp
export CORE_PEER_ADDRESS=localhost:9051