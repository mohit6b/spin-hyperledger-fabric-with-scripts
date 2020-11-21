#!/bin/bash

#Form arrays for all the variables passed as parameters from outside the container
function getExports() {
    while [ $1 != "." ]
    do
        ORG_LIST+=($1)
        shift
    done

    shift

    while [ $1 != "." ]
    do
        ORG_MSP_LIST+=($1)
        shift
    done

    shift

    while [ $1 != "." ]
    do
        PEER_LIST+=($1)
        shift
    done

    shift

    while [ $1 != "." ]
    do
        PEER_LIST_BOUNDARIES+=($1)
        shift
    done

    shift

    while [ $1 != "." ]
    do
        PEER_PORT_LIST+=($1)
        shift
    done

    shift

    choice=$1
    shift

    CHANNEL_NAME=$1
    shift

    while [ $1 != "." ]
    do
        ANCHOR_PEER_BOOLEAN+=($1)
        shift
    done

    shift
    while [ $1 != "." ]
    do
        ORDERER_ORG_LIST+=($1)
        shift
    done

    shift
    while [ $1 != "." ]
    do
        ORDERER_LIST+=($1)
        shift
    done

    shift
    while [ $1 != "." ]
    do
        ORDERER_MSPID_LIST+=($1)
        shift
    done

    shift
    while [ $1 != "." ]
    do
        ORDERER_PORTS+=($1)
        shift
    done

    shift

    while [ $1 != "." ]
    do
        ORDERER_BOUNDARIES_LIST+=($1)
        shift
    done

    shift

    ORDERER_MAIN_PORT=$1
    shift

    CHANNEL_ORDERER=$1
    shift
    
    while [ $1 != "." ]
    do
        JOINING_PEERS+=($1)
        shift
    done

    shift

    CHAINCODE_ADDON=$1
    shift

    CHAINCODE_NAME=$1
    shift

    CHAINCODE_LANGUAGE=$1
    shift

    while [ $1 != "." ]
    do
        CHANNEL_CHAINCODE_BOOLEAN_LIST+=($1)
        shift
    done

    shift

    while [ $1 != "." ]
    do
        ARGS_STRING="${ARGS_STRING}${1}"
        shift
    done

    echo $ARGS_STRING
    shift


    while [ $1 != "." ]
    do
        ENDORSEMENT_POLICY="${ENDORSEMENT_POLICY}${1}"
        shift
    done

    echo $ENDORSEMENT_POLICY
    shift
    CHAINCODE_PATH=$1
    shift
    echo $CHAINCODE_PATH
}

#This function determines the index of the ordererOrg whose orderer is being 
#used to run the commands
function findChannelOrdererOrg() {
    i=0
    while [ $CHANNEL_ORDERER -ge ${ORDERER_BOUNDARIES_LIST[$i]} ]
    do
        i=`expr $i + 1`
    done
    CHANNEL_ORDERER_ORG_INDEX=`expr $i - 1`
}

#This function takes one parameter (index of peer + 1) and sets the required 
#Environment variables
function setEnvVariables() {
    #Find org and peer indices
    peer_index=`expr $1 - 1`
    org_index=0
    for i in ${PEER_LIST_BOUNDARIES[@]:1}
    do
        if [ $peer_index -lt $i ]; then
            break
        fi
        org_index=`expr $org_index + 1`
    done
    echo "$peer_index $org_index"

    #Set the required environment variables
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORG_LIST[$org_index]}/users/Admin@${ORG_LIST[$org_index]}/msp
    CORE_PEER_ADDRESS=${PEER_LIST[$peer_index]}:${PEER_PORT_LIST[$peer_index]}
    CORE_PEER_LOCALMSPID="${ORG_MSP_LIST[$org_index]}"
    CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/${ORG_LIST[$org_index]}/peers/${PEER_LIST[$peer_index]}/tls/ca.crt
    
    echo "CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS"
    echo "CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID"
    echo "CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH"
    echo "CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE"
}

#This function creates the channel
function createChannel() {
    #Set the environment variables for the peer with which we set channel up
    echo
    echo
    echo "------------------------------------------------------------"
    echo "------------------- Creating the Channel -------------------"
    echo "------------------------------------------------------------"
    echo
    setEnvVariables $choice

    #Channel Creation
    peer channel create -o ${ORDERER_LIST[$CHANNEL_ORDERER]}:${ORDERER_MAIN_PORT} -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ORDERER_ORG_LIST[$CHANNEL_ORDERER_ORG_INDEX]}/orderers/${ORDERER_LIST[$CHANNEL_ORDERER]}/msp/tlscacerts/tlsca.${ORDERER_ORG_LIST[$CHANNEL_ORDERER_ORG_INDEX]}-cert.pem
}

#This function joins the selected peers to the channel
function joinPeers() {
    #Loop through the peers and join each one to the channel
    k=1
    while [ $k -le ${#PEER_LIST[@]} ]
    do
        if [ ${JOINING_PEERS[$k-1]} -eq 1 ]; then
            echo
            echo
            echo "------------------------------------------------------------"
            echo "--------- Joining Peer ${PEER_LIST[$k-1]} ---------"
            echo "------------------------------------------------------------"          
            echo
            setEnvVariables $k
            peer channel join -b  $CHANNEL_NAME.block
        fi
        k=`expr $k + 1`
        #sleep 15
    done
}

#This function updates the anchor peers for each org
function updateAnchorPeers() {
    echo
    echo
    echo "-----------------------------------------------------------"
    echo "---------------- Updating the Anchor Peers ----------------"
    echo "-----------------------------------------------------------"
    echo    
    k=0
    l=0
    for i in ${PEER_LIST[@]}
    do
        if [ ${ANCHOR_PEER_BOOLEAN[$k]} -eq 1 ]; then
            setEnvVariables `expr $k + 1`
            peer channel update -o ${ORDERER_LIST[$CHANNEL_ORDERER]}:${ORDERER_MAIN_PORT} -c $CHANNEL_NAME -f ./channel-artifacts/${ORG_MSP_LIST[${org_index}]}Anchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ORDERER_ORG_LIST[$CHANNEL_ORDERER_ORG_INDEX]}/orderers/${ORDERER_LIST[$CHANNEL_ORDERER]}/msp/tlscacerts/tlsca.${ORDERER_ORG_LIST[$CHANNEL_ORDERER_ORG_INDEX]}-cert.pem
        fi
        k=`expr $k + 1`
    done
}

function installChaincode() {
    #Loop through the peers and join each one to the channel
    k=1
    while [ $k -le ${#PEER_LIST[@]} ]
    do
        if [ ${CHANNEL_CHAINCODE_BOOLEAN_LIST[$k-1]} -eq 1 ]; then
            echo
            echo
            echo "----------------------------------------------------------------------"
            echo "--------- Installing chaincode on Peer ${PEER_LIST[$k-1]} ---------"
            echo "----------------------------------------------------------------------"          
            echo
            setEnvVariables $k
            if [ $CHAINCODE_LANGUAGE = "go" ]; then
                peer chaincode install -n $CHAINCODE_NAME -v 1.0 -p github.com/chaincode/${CHAINCODE_PATH}/
            else
                peer chaincode install -n $CHAINCODE_NAME -v 1.0 -l ${CHAINCODE_LANGUAGE} -p /opt/gopath/src/github.com/chaincode/${CHAINCODE_PATH}/
            fi
        fi
        k=`expr $k + 1`
    done
}

function instantiateChaincode() {
    echo
    echo "---------------------------------------------------------"
    echo "---------------- Instantiating Chaincode ----------------"
    echo "---------------------------------------------------------"
    echo
    set -x
    peer chaincode instantiate -o ${ORDERER_LIST[$CHANNEL_ORDERER]}:${ORDERER_MAIN_PORT} --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/${ORDERER_ORG_LIST[$CHANNEL_ORDERER_ORG_INDEX]}/orderers/${ORDERER_LIST[$CHANNEL_ORDERER]}/msp/tlscacerts/tlsca.${ORDERER_ORG_LIST[$CHANNEL_ORDERER_ORG_INDEX]}-cert.pem -C $CHANNEL_NAME -n ${CHAINCODE_NAME} -v 1.0 -c '{"Args":["init","a","10","b","100"]}' -P "OR ('edges.peer', 'curlhg.client', 'curlhg.peer')"
    set +x
}



#Executed part of the script begins here
getExports $@
findChannelOrdererOrg

createChannel
joinPeers
updateAnchorPeers


if [ $CHAINCODE_ADDON -eq 1 ]; then
    installChaincode
    instantiateChaincode
fi