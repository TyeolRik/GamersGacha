#!/bin/bash

# Using binaries execution
export PATH=$PATH:${PWD}/bin

## Environment variables
export FABRIC_CFG_PATH=${PWD}/config
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/gamersgacha.com/orderers/Gamers-Gacha.gamersgacha.com/msp/tlscacerts/tlsca.gamersgacha.com-cert.pem

### For Nexon
export Nexon_CORE_PEER_LOCALMSPID=NexonMSP
export Nexon_CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/nexon.example.com/peers/peer0.nexon.example.com/tls/ca.crt
export Nexon_CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/nexon.example.com/users/Admin@nexon.example.com/msp
export Nexon_CORE_PEER_ADDRESS=localhost:7051

### For Netmarble
export Netmarble_CORE_PEER_LOCALMSPID=NetmarbleMSP
export Netmarble_CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/netmarble.example.com/peers/peer0.netmarble.example.com/tls/ca.crt
export Netmarble_CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/netmarble.example.com/users/Admin@netmarble.example.com/msp
export Netmarble_CORE_PEER_ADDRESS=localhost:9051

### For NCsoft
export NCsoft_CORE_PEER_LOCALMSPID=NCsoftMSP
export NCsoft_CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/ncsoft.example.com/peers/peer0.ncsoft.example.com/tls/ca.crt
export NCsoft_CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/ncsoft.example.com/users/Admin@ncsoft.example.com/msp
export NCsoft_CORE_PEER_ADDRESS=localhost:11051

input=$1

if [ $input -eq 1 ] ; then
    peer chaincode query -C test-net1 -n randomtest -c '{"Args":["GetAllRandomBox"]}'
fi

if [ $input == "open" ] ; then
    peer chaincode invoke \
        -o localhost:7050 \
        --ordererTLSHostnameOverride Gamers-Gacha.gamersgacha.com \
        --tls \
        --cafile $ORDERER_CA \
        -C test-net1 \
        -n randomtest \
        --peerAddresses $Nexon_CORE_PEER_ADDRESS \
        --tlsRootCertFiles $Nexon_CORE_PEER_TLS_ROOTCERT_FILE \
        --peerAddresses $Netmarble_CORE_PEER_ADDRESS \
        --tlsRootCertFiles $Netmarble_CORE_PEER_TLS_ROOTCERT_FILE \
        --peerAddresses $NCsoft_CORE_PEER_ADDRESS \
        --tlsRootCertFiles $NCsoft_CORE_PEER_TLS_ROOTCERT_FILE \
        -c '{"function":"OpenRandomBox","Args":["MapleStory","Scania","Hero1","Randombox1","100000"]}'
fi