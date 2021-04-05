#!/bin/bash

# peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n randomtest --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c '{"function":"OpenRandomBox","Args":["MapleStory","Scania","Hero1","Randombox1","100000"]}'

# Random Generation in Linux :: shuf -i 0-5 -n 1

# Before Starting Run this in /fabric-sample/test-network
# export PATH=${PWD}/../bin:$PATH && export FABRIC_CFG_PATH=$PWD/../config/ && export CORE_PEER_TLS_ENABLED=true && export CORE_PEER_LOCALMSPID="Org1MSP" && export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt && export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp && export CORE_PEER_ADDRESS=localhost:7051

# Maximum User 100000
userNumber=100000
# 0: MapleStory, 1: LOL, 2: PUBG, 3: LostArk, 4: FIFAOnline, 5: Overwatch, 6: SuddenAttack, 7: Dota2, 8: Lineage, 9: Valorant
game=("MapleStory" "LOL" "PUBG" "LostArk" "FIFAOnline" "Overwatch" "SuddenAttack" "Dota2" "Lineage" "Valorant")
gameNumber=-1

HeroName="Hero"
timestamp=$(($(date +%s%N)/1000000))

for((i=0; i < 30001; i++))
do
    gameNumber=$(shuf -i 0-9 -n 1)
    HeroNumber=$(shuf -i 1-${userNumber} -n 1)
    HeroName="Hero${HeroNumber}"
    # JSON='{"function":"OpenRandomBox","Args":["'"${game[${gameNumber}]}"'","Scania","'"${HeroName}"'","Randombox1","100000"]}'
    # JSON='{"function":"OpenRandomBoxes","Args":["'"${game[${gameNumber}]}"'","Scania","'"${HeroName}"'","Randombox1","100000","11"]}'
    JSON='{"function":"OpenRandomBoxes","Args":["'"${game[${gameNumber}]}"'","Scania","'"${HeroName}"'","Randombox1","100000","100"]}'
    peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n randomtest --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c ${JSON} > /dev/null 2>&1
    # peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" -C mychannel -n randomtest --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" -c ${JSON}

    if [ $(($i%1000)) -eq 0 ]
    then
        newTime=$(($(date +%s%N)/1000000))
        cost=$(($newTime-$timestamp))
        echo -e "$i\tTime Cost : $cost ms"
        timestamp=$newTime
    fi
done