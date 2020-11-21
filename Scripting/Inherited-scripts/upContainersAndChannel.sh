#!/bin/bash

#This function starts the docker containers and runs another script from within
#the client container
function startNetwork() {
    rm ./scripts/container-script.sh

    sed -e "s/__ARGS__STRING__/${ARGS_STRING}/" -e "s/__ENDORSEMENT__POLICY__/${POLICY}/" ./templates/container-script-template.sh >> ./scripts/container-script.sh
    sudo chmod 777 ./scripts/container-script.sh
    cd $FABRIC_CFG_PATH
    if [ $ORDERER_TYPE = "kafka" ]; then
        docker-compose -f docker-compose-cli.yaml -f docker-compose-ca.yaml -f docker-compose-kafka.yaml up -d
        echo "Waiting 30s for kafka cluster to boot"
        sleep 30
    else
        docker-compose -f docker-compose-cli.yaml -f docker-compose-ca.yaml up -d
    fi
    
    docker ps -a

    echo
    echo "All the containers are now up"
    echo
    echo
    echo "--------------------------------------------------------------------"
    echo "-------------------- Move into client container --------------------"
    echo "--------------------------------------------------------------------"
    echo
    echo
    echo
    

    #This is used to call the script from within the container
    docker exec cli scripts/container-script.sh ${CHANNEL_ORGS_DOMAINS[@]} "." ${CHANNEL_ORGS[@]} "." ${CHANNEL_PEERS[@]} "." ${CHANNEL_PEER_BOUNDARIES_LIST[@]} "." ${CHANNEL_PEER_PORTS[@]} "." $CHANNEL_CREATOR $CHANNEL_NAME ${ANCHOR_PEER_LIST[@]} "." ${ORDERER_ORG_LIST[@]} "." ${ORDERER_LIST[@]} "." ${ORDERER_MSPID_LIST[@]} "." ${ORDERER_PORTS[@]} "." ${ORDERER_BOUNDARIES_LIST[@]} "." ${ORDERER_MAIN_PORT} $CHANNEL_ORDERER ${JOINING_PEERS[@]} "." $CHAINCODE_ADDON $CHAINCODE_NAME $CHAINCODE_LANGUAGE ${CHANNEL_CHAINCODE_BOOLEAN_LIST[@]} "." $ARGS_STRING "." $POLICY "." $CHAINCODE_PATH
}