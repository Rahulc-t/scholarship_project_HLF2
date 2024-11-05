#!/bin/bash

echo "------------Register the ca admin for each organization—----------------"

docker compose -f docker/docker-compose-ca.yaml up -d
sleep 3
sudo chmod -R 777 organizations/

echo "------------Register and enroll the users for each organization—-----------"

chmod +x registerEnroll.sh

./registerEnroll.sh
sleep 3

echo "—-------------Build the infrastructure—-----------------"

docker compose -f docker/docker-compose-4org.yaml up -d
sleep 3

echo "-------------Generate the genesis block—-------------------------------"

export FABRIC_CFG_PATH=${PWD}/config

export CHANNEL_NAME=mychannel
echo "###########################################################"
echo ${CHANNEL_NAME}

configtxgen -profile ChannelUsingRaft -outputBlock ${PWD}/channel-artifacts/${CHANNEL_NAME}.block -channelID $CHANNEL_NAME

echo "------ Create the application channel------"

export ORDERER_CA=${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/msp/tlscacerts/tlsca.scholar.com-cert.pem

export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls/server.crt

export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/scholar.com/orderers/orderer.scholar.com/tls/server.key

osnadmin channel join --channelID $CHANNEL_NAME --config-block ${PWD}/channel-artifacts/$CHANNEL_NAME.block -o localhost:7053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
sleep 2
osnadmin channel list -o localhost:7053 --ca-file $ORDERER_CA --client-cert $ORDERER_ADMIN_TLS_SIGN_CERT --client-key $ORDERER_ADMIN_TLS_PRIVATE_KEY
sleep 2

export FABRIC_CFG_PATH=${PWD}/peercfg
export UNIVERSITY_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/tls/ca.crt
export SCHOLARSHIPDEPARTMENT_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/tls/ca.crt
export TREASURY_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/tls/ca.crt
export AUDITOR_PEER_TLSROOTCERT=${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/tls/ca.crt

export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID=scholarshipDepartmentMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/peers/peer0.scholarshipDepartment.scholar.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/scholarshipDepartment.scholar.com/users/Admin@scholarshipDepartment.scholar.com/msp
export CORE_PEER_ADDRESS=localhost:7051
sleep 2

echo "—---------------Join scholarshipDepartment peer to the channel—-------------"

echo ${FABRIC_CFG_PATH}
sleep 2
peer channel join -b ${PWD}/channel-artifacts/${CHANNEL_NAME}.block
sleep 3

echo "-----channel List----"
peer channel list

echo "—-------------scholarshipDepartment anchor peer update—-----------"


peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
sleep 1

cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json

cp config.json config_copy.json

jq '.channel_group.groups.Application.groups.scholarshipDepartmentMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.scholarshipDepartment.scholar.com","port": 7051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..

peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.scholar.com --tls --cafile $ORDERER_CA
sleep 1

echo "—---------------package chaincode—-------------"


# cp -r ../fabric-samples/asset-transfer-basic/chaincode-javascript ../Chaincode

# peer lifecycle chaincode package basic.tar.gz --path ../Chaincode/chaincode-javascript/ --lang node --label basic_1.0

peer lifecycle chaincode package scholarship.tar.gz --path ${PWD}/../chaincode --lang node --label scholarship_1.0
sleep 1

export CC_PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid scholarship.tar.gz)

echo "—---------------install chaincode in scholarshipDepartment peer—-------------"

peer lifecycle chaincode install scholarship.tar.gz
sleep 3

peer lifecycle chaincode queryinstalled

echo "—---------------Approve chaincode in scholarshipDepartment peer—-------------"

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com --channelID $CHANNEL_NAME --name scholarship --version 1.0 --collections-config ../chaincode/collection-scholarships.json --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
sleep 2

#NEW
export CORE_PEER_LOCALMSPID=universityMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer0.university.scholar.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/university.scholar.com/users/Admin@university.scholar.com/msp
export CORE_PEER_ADDRESS=localhost:5051
sleep 2

echo "—---------------Join university peer to the channel—-------------"

echo ${FABRIC_CFG_PATH}
sleep 2
peer channel join -b ${PWD}/channel-artifacts/${CHANNEL_NAME}.block
sleep 3

echo "-----channel List----"
peer channel list

echo "—-------------university anchor peer update—-----------"


peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
sleep 1

cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json

cp config.json config_copy.json

jq '.channel_group.groups.Application.groups.universityMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.university.scholar.com","port": 5051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..

peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.scholar.com --tls --cafile $ORDERER_CA
sleep 1

# END1
echo "—---------------install chaincode in university peer0—-------------"

peer lifecycle chaincode install scholarship.tar.gz
sleep 3

peer lifecycle chaincode queryinstalled

echo "—---------------Approve chaincode in university peer0—-------------"

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com --channelID $CHANNEL_NAME --name scholarship --version 1.0 --collections-config ../chaincode/collection-scholarships.json --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
sleep 2
export CORE_PEER_LOCALMSPID=universityMSP
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/university.scholar.com/peers/peer1.university.scholar.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/university.scholar.com/users/Admin@university.scholar.com/msp
export CORE_PEER_ADDRESS=localhost:4051
sleep 2

echo "—---------------Join university peer1 to the channel—-------------"

echo ${FABRIC_CFG_PATH}
sleep 2
peer channel join -b ${PWD}/channel-artifacts/${CHANNEL_NAME}.block
sleep 3

echo "-----channel List----"
peer channel list
#END2
echo "—---------------install chaincode in scholarshipDepartment peer1—-------------"

peer lifecycle chaincode install scholarship.tar.gz
sleep 3

peer lifecycle chaincode queryinstalled

echo "—---------------Approve chaincode in scholarshipDepartment peer1—-------------"

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com --channelID $CHANNEL_NAME --name scholarship --version 1.0 --collections-config ../chaincode/collection-scholarships.json --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
sleep 2

export CORE_PEER_LOCALMSPID=treasuryMSP 
export CORE_PEER_ADDRESS=localhost:9051 
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/treasury.scholar.com/peers/peer0.treasury.scholar.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/treasury.scholar.com/users/Admin@treasury.scholar.com/msp

echo "—---------------Join treasury peer to the channel—-------------"

peer channel join -b ${PWD}/channel-artifacts/$CHANNEL_NAME.block
sleep 1
peer channel list

echo "—-------------treasury anchor peer update—-----------"


peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
sleep 1

cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json

cp config.json config_copy.json

jq '.channel_group.groups.Application.groups.treasuryMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.treasury.scholar.com","port": 9051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..

peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.scholar.com --tls --cafile $ORDERER_CA
sleep 1
echo "—---------------install chaincode in treasury peer0—-------------"

peer lifecycle chaincode install scholarship.tar.gz
sleep 3

peer lifecycle chaincode queryinstalled

echo "—---------------Approve chaincode in treasury peer0—-------------"

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com --channelID $CHANNEL_NAME --name scholarship --version 1.0 --collections-config ../chaincode/collection-scholarships.json --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
sleep 2
# echo "—---------------install chaincode in treasury peer—-------------"

# peer lifecycle chaincode install basic.tar.gz
# sleep 3

# peer lifecycle chaincode queryinstalled

# echo "—---------------Approve chaincode in treasury peer—-------------"

# peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com --channelID $CHANNEL_NAME --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
# sleep 1


#new start
export CORE_PEER_LOCALMSPID=auditorMSP 
export CORE_PEER_ADDRESS=localhost:6051 
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/auditor.scholar.com/peers/peer0.auditor.scholar.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/auditor.scholar.com/users/Admin@auditor.scholar.com/msp

echo "—---------------Join auditor peer to the channel—-------------"

peer channel join -b ${PWD}/channel-artifacts/$CHANNEL_NAME.block
sleep 1
peer channel list

echo "—-------------auditor anchor peer update—-----------"


peer channel fetch config ${PWD}/channel-artifacts/config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com -c $CHANNEL_NAME --tls --cafile $ORDERER_CA
sleep 1

cd channel-artifacts

configtxlator proto_decode --input config_block.pb --type common.Block --output config_block.json
jq '.data.data[0].payload.data.config' config_block.json > config.json

cp config.json config_copy.json

jq '.channel_group.groups.Application.groups.auditorMSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": [{"host": "peer0.auditor.scholar.com","port": 6051}]},"version": "0"}}' config_copy.json > modified_config.json

configtxlator proto_encode --input config.json --type common.Config --output config.pb
configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb
configtxlator compute_update --channel_id ${CHANNEL_NAME} --original config.pb --updated modified_config.pb --output config_update.pb

configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate --output config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope --output config_update_in_envelope.pb

cd ..

peer channel update -f ${PWD}/channel-artifacts/config_update_in_envelope.pb -c $CHANNEL_NAME -o localhost:7050  --ordererTLSHostnameOverride orderer.scholar.com --tls --cafile $ORDERER_CA
sleep 1
#new end

echo "—---------------install chaincode in auditor peer0—-------------"

peer lifecycle chaincode install scholarship.tar.gz
sleep 3

peer lifecycle chaincode queryinstalled

echo "—---------------Approve chaincode in auditor peer0—-------------"

peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com --channelID $CHANNEL_NAME --name scholarship --version 1.0 --collections-config ../chaincode/collection-scholarships.json --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
sleep 2


echo "—---------------Commit chaincode in auditor peer0—-------------"

peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name scholarship --version 1.0 --sequence 1 --collections-config ../chaincode/collection-scholarships.json --tls --cafile $ORDERER_CA --output json

peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com --channelID $CHANNEL_NAME --name scholarship --version 1.0 --sequence 1 --collections-config ../chaincode/collection-scholarships.json --tls --cafile $ORDERER_CA --peerAddresses localhost:5051 --tlsRootCertFiles $UNIVERSITY_PEER_TLSROOTCERT --peerAddresses localhost:7051 --tlsRootCertFiles $SCHOLARSHIPDEPARTMENT_PEER_TLSROOTCERT --peerAddresses localhost:6051 --tlsRootCertFiles $AUDITOR_PEER_TLSROOTCERT --peerAddresses localhost:9051 --tlsRootCertFiles $TREASURY_PEER_TLSROOTCERT
sleep 1

peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name scholarship --cafile $ORDERER_CA
# peer lifecycle chaincode querycommitted --collections-config ../chaincode/collection-scholarships.json -C $CHANNEL_NAME -n scholarship

# echo "—---------------install chaincode in artBuyer peer—-------------"

# peer lifecycle chaincode install basic.tar.gz
# sleep 3

# peer lifecycle chaincode queryinstalled

# echo "—---------------Approve chaincode in artBuyer peer—-------------"

# peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com --channelID $CHANNEL_NAME --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1 --tls --cafile $ORDERER_CA --waitForEvent
# sleep 1


# echo "—---------------Commit chaincode in artBuyer peer—-------------"


# peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name basic --version 1.0 --sequence 1 --tls --cafile $ORDERER_CA --output json

# peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.scholar.com --channelID $CHANNEL_NAME --name basic --version 1.0 --sequence 1 --tls --cafile $ORDERER_CA --peerAddresses localhost:7051 --tlsRootCertFiles $scholarshipDepartment_PEER_TLSROOTCERT --peerAddresses localhost:9051 --tlsRootCertFiles $treasury_PEER_TLSROOTCERT  --peerAddresses localhost:6051 --tlsRootCertFiles $auditor_PEER_TLSROOTCERT
# sleep 1

# peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name basic --cafile $ORDERER_CA