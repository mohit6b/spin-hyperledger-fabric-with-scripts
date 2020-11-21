#!/bin/bash

#This function adds the peer and orderer containers that inherit
#from docker-compose-base.yaml and appends it onto docker-compose-cli.yaml
function addContainers() {
    for i in ${ORDERER_LIST[@]}
    do
        sed -e "s/\$CONTAINER_NAME/$i/g" \
            -e "s/\$NETWORK_NAME/$NETWORK_NAME/" \
            ./templates/docker-compose-template.yaml >> docker-compose-cli.yaml
    done
    for i in ${PEER_LIST[@]}
    do
        sed -e "s/\$CONTAINER_NAME/$i/g" \
            -e "s/\$NETWORK_NAME/$NETWORK_NAME/" \
            ./templates/docker-compose-template.yaml >> docker-compose-cli.yaml
    done
}

#This function appends the volumes and networks section of docker-compose-cli.yaml
function addVolumesAndNetworks() {
    echo -e "volumes:" >> docker-compose-cli.yaml
    for i in ${ORDERER_LIST[@]}
    do
        echo -e "  $i:" >> docker-compose-cli.yaml
    done
    for i in ${PEER_LIST[@]}
    do
        echo -e "  $i:" >> docker-compose-cli.yaml
    done
    echo -e "\nnetworks:\n  $NETWORK_NAME:\n" >> docker-compose-cli.yaml
}

#This function is used to add the client container to the file
#It takes the peer that the client operates as input
function addClient() {
    echo
    echo
    echo "Select the peer to use from client container:"
    i=1
    while [ $i -le ${#CHANNEL_PEERS[@]} ]
    do
        echo "${i}. ${CHANNEL_PEERS[$i-1]}"
        i=`expr $i + 1`
    done
    echo
    while :
    do
        read -p "Enter your choice: " choice
        if [[ ! $choice =~ ^[0-9]+$ ]]; then
            echo "Invalid"
            continue
        fi
        if [ $choice -le 0 -o $choice -ge $i ]; then
            echo "Invalid"
            continue
        fi
        break
    done
    i=`expr $choice - 1`
    j=0
    while [ $i -ge ${CHANNEL_PEER_BOUNDARIES_LIST[$j+1]} ]
    do
        j=`expr $j + 1`
    done
    DOMAIN=${ORG_LIST[$j]}
    MSPID=${ORG_MSPID_LIST[$j]}
    sed -e "s/\$PEER_NAME/${PEER_LIST[$i]}/g" \
        -e "s/\$PEER_PORT/${PEER_LISTEN_PORTS[$i]}/g" \
        -e "s/\$MSPID/$MSPID/" \
        -e "s/\$ORG_NAME/$DOMAIN/g" \
        -e "s/\$NETWORK_NAME/$NETWORK_NAME/" \
        ./templates/docker-compose-cli-template.yaml >> docker-compose-cli.yaml
    for i in ${ORDERER_LIST[@]}
    do
        echo -e "      - $i" >> docker-compose-cli.yaml
    done
    for i in ${PEER_LIST[@]}
    do
        echo -e "      - $i" >> docker-compose-cli.yaml
    done
}

#This function is used to create the entire docker-compose-cli.yaml file
#from scratch. It calls the other functions
function makeDockerComposeCli() {
    echo -e "version: '2'\n" >> docker-compose-cli.yaml
    addVolumesAndNetworks
    echo -e "services:" >> docker-compose-cli.yaml
    addContainers
    addClient
}