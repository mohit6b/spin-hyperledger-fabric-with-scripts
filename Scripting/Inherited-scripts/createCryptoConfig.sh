#!/bin/bash

#This file reads the inputs required for the crypto-config.yaml file
#It creates crypto-config.yaml from scratch


#Function to replace the parameters and append onto crypto-config.yaml
function replaceInTemplate() {
    if [ $5 = "peer" ]; then
        #sed is a tool used to replace matched strings from files
        sed -e "s/\$ORG_NAME/$1/" \
            -e "s/\$ORG_DOMAIN/$2/" \
            -e "s/\$PEER_NUMBER/$3/" \
            -e "s/\$USER_NUMBER/$4/" \
            ./templates/crypto-config-template.yaml >> crypto-config.yaml
    else
        sed "/\$PEER_NUMBER/q" ./templates/crypto-config-template.yaml | \
        sed -e "s/\$ORG_NAME/$1/" \
            -e "s/\$ORG_DOMAIN/$2/" \
            -e "s/\$PEER_NUMBER/$3/" \
            -e "s/\$USER_NUMBER/$4/" >> crypto-config.yaml
    fi
}

#Function to add a new organization's details
#This function also creates arrays for the org details
#Such as list of ordererOrgs and peerOrgs
function addNewOrg() {
    #Take details of org as input from the user
    echo
    echo "Adding new ${1}Organization. Enter the details:"
    echo "-----------------------------------------------"
    read -p "Name: " ORG_NAME
    read -p "Domain: " ORG_DOMAIN
    if [ $1 == "peer" ]; then
        read -p "Number of peers: " PEER_NUMBER
        PEER_BOUNDARIES_LIST+=(`expr ${PEER_BOUNDARIES_LIST[-1]} + ${PEER_NUMBER}`)
        ORG_LIST+=($ORG_DOMAIN)
        ORG_MSPID_LIST+=($ORG_NAME)
        ANCHOR_PEER_ORG_LIST+=(0)
        k=0
        while [ $k -lt $PEER_NUMBER ]
        do
            PEER_LIST+=("peer$k.$ORG_DOMAIN")
            ANCHOR_PEER_LIST+=(0)
            k=`expr $k + 1`
        done
        read -p "Number of users: " USER_NUMBER
        replaceInTemplate $ORG_NAME $ORG_DOMAIN $PEER_NUMBER $USER_NUMBER "peer"
    else
        if [ "$ORDERER_TYPE" = "etcdraft" -o "$ORDERER_TYPE" = "kafka" ]; then
            read -p "Number of orderers: " PEER_NUMBER
        else
            echo "Number of orderers: 1"
            PEER_NUMBER=1
        fi
        ORDERER_BOUNDARIES_LIST+=(`expr ${ORDERER_BOUNDARIES_LIST[-1]} + ${PEER_NUMBER}`)
        ORDERER_ORG_LIST+=($ORG_DOMAIN)
        ORDERER_MSPID_LIST+=($ORG_NAME)
        k=0
        while [ $k -lt $PEER_NUMBER ]
        do
            ORDERER_LIST+=("orderer$k.$ORG_DOMAIN")
            k=`expr $k + 1`
        done
        replaceInTemplate $ORG_NAME $ORG_DOMAIN $PEER_NUMBER . "orderer"
    fi    
}

#Add the Orderer Organizations to the crypto-config.yaml file
function createOrdererOrgs() {
    echo
    echo
    read -p "Enter the network name (Small letters only, no spaces or special characters): " NETWORK_NAME
    export NETWORK_NAME=$NETWORK_NAME
    echo
    echo "--------------------------------------------------------------------------------"
    echo "--------------------- Creating the crypto-config.yaml file ---------------------"
    echo "--------------------------------------------------------------------------------"
    echo
    echo "Enter Orderer Type:"
    echo "1. Solo"
    echo "2. Kafka"
    echo "3. Raft"
    read -p "Enter your choice: " ORDERER_TYPE
    case $ORDERER_TYPE in
    1)
        ORDERER_TYPE="solo"
        ;;
    2)
        ORDERER_TYPE="kafka"
        ;;
    3)
        ORDERER_TYPE="etcdraft"
        ;;
    *)
        echo "Invalid Orderer Type"
        createOrdererOrgs
        return
        ;;
    esac
    echo
    echo "-------------------------------"
    echo -ne "Enter "
    echo "OrdererOrgs:"
    echo "OrdererOrgs:" >> crypto-config.yaml
    echo "-------------------------------"

    ORDERER_BOUNDARIES_LIST+=(0)

    if [ "$ORDERER_TYPE" = "etcdraft" ]; then
        proceed=y        
        #Loop and ask user to enter another org
        while :
        do
            case $proceed in
            "y"|"Y"|"")
                addNewOrg "orderer"
                ;;
            "n"|"N")
                break
                ;;
            *)
                echo "Invalid choice."
                ;;
            esac
            echo
            read -p "Do you want to add another ordererOrg? (y/n) :" proceed
            echo
        done
        
    else
        addNewOrg "orderer"
    fi
}


#Add the Peer Organizations to the crypto-config.yaml file
function createPeerOrgs() {
    echo "-------------------------------"
    echo -n "Enter "
    echo "PeerOrgs:"
    echo -e "\nPeerOrgs:" >> crypto-config.yaml
    echo "-------------------------------"

    proceed=y
    PEER_BOUNDARIES_LIST+=(0)
    addNewOrg "peer"

    #Loop and ask user to enter another org
    while :
    do
        echo
        read -p "Do you want to add another peerOrg? (y/n) :" proceed
        echo
        case $proceed in
        "y"|"Y"|"")
            addNewOrg "peer"
            ;;
        "n"|"N")
            break
            ;;
        *)
            echo "Invalid"
            ;;
        esac
    done
}