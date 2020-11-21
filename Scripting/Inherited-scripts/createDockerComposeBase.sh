#!/bin/bash

#This function replaces the current instance values in the template
#And appends it onto docker-compose-base.yaml for orderer peers
function addOrdererContainers() {
    i=0
    j=0
    DOMAIN=${ORDERER_ORG_LIST[$j]}
    ORDER_MSP=${ORDERER_MSPID_LIST[$j]}
    while [ $i -lt ${#ORDERER_LIST[@]} ]
    do
        if [ $i -eq ${ORDERER_BOUNDARIES_LIST[${j}+1]} ]; then
            j=`expr $j + 1`
            DOMAIN=${ORDERER_ORG_LIST[$j]}
            ORDER_MSP=${ORDERER_MSPID_LIST[$j]}
            echo "${ORDER_MSP}.....${DOMAIN}"
        fi
        sed -e "s/\$ORDERER_NAME/${ORDERER_LIST[$i]}/g" \
            -e "s/\$ORDERER_DOMAIN/$DOMAIN/g" \
            -e "s/\$ORDERER_PORT/${ORDERER_PORTS[$i]}/" \
            -e "s/\$MAIN_PORT/$ORDERER_MAIN_PORT/" \
            -e "s/\$ORDERER_MSP/$ORDER_MSP/" \
            ./templates/base-orderer-template.yaml >> ./base/docker-compose-base.yaml
        i=`expr $i + 1`
    done
}

#This function replaces the current instance values in the template
#And appends it onto docker-compose-base.yaml for peers
function addPeerContainers() {
    i=0
    j=0
    DOMAIN=${ORG_LIST[$j]}
    MSP=${ORG_MSPID_LIST[$j]}
    GOSSIP_PEER="${PEER_LIST[$i]}:${PEER_LISTEN_PORTS[$i]}"
    while [ $i -lt ${#PEER_LIST[@]} ]
    do
        if [ $i -eq ${PEER_BOUNDARIES_LIST[${j}+1]} ]; then
            j=`expr $j + 1`
            DOMAIN=${ORG_LIST[$j]}
            MSP=${ORG_MSPID_LIST[$j]}
            GOSSIP_PEER="${PEER_LIST[$i]}:${PEER_LISTEN_PORTS[$i]}"
        fi
        sed -e "s/\$PEER_NAME/${PEER_LIST[$i]}/g" \
            -e "s/\$GOSSIP_PEER/$GOSSIP_PEER/" \
            -e "s/\$LISTEN_PORT/${PEER_LISTEN_PORTS[$i]}/g" \
            -e "s/\$CC_PORT/${PEER_CC_PORTS[$i]}/g" \
            -e "s/\$ORG_NAME/${DOMAIN}/g" \
            -e "s/\$MSPID/$MSP/g" \
            -e "s/\$NETWORK_NAME/$NETWORK_NAME/" \
            ./templates/base-peer-template.yaml >> ./base/docker-compose-base.yaml
        i=`expr $i + 1`
    done
}

#This function completely creates the docker-compose-base.yaml file
#It calls the other two functions in the file
function makeDockerComposeBase() {
    echo "---------------------------------------------------"
    echo "---------- Creating Docker Compose Files ----------"
    echo "---------------------------------------------------"
    echo -e "version: '2'\n\nservices:" >> ./base/docker-compose-base.yaml
    addOrdererContainers
    addPeerContainers
}