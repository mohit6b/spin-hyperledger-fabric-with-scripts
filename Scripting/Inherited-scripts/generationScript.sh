#!/bin/bash

#Function to generate certificates
function generateCerts() { 
    echo
    echo
    echo "-----------------------------------------------------------------"
    echo "-------------------- Generating certificates --------------------"
    echo "-----------------------------------------------------------------"
    echo
    
    #Check if cryptogen exists
    which cryptogen
    if [ "$?" -ne 0 ]; then
        echo "Cryptogen tool not found. Exiting..."
        exit 1
    fi

    #Check if certificates have already been generated
    if [ -d crypto ]
    then
        echo "Deleting existing certificates"
        rm -Rf crypto
    fi 

    #Generating certificates
    set -x
    cryptogen generate --config=./crypto-config.yaml --output=crypto
    res=$?
    set +x
    if [ $res -ne 0 ]
    then
        echo "Failed to generate certificates..."
        exit 1
    fi
    echo
    echo
}

#Function to generate the different channel artifacts
#Creates genesis block, channel config, anchor peer updates
#Stores in ./channel-artifacts/
function generateArtifacts() {
    echo
    echo
    echo "------------------------------------------------------------"
    echo "----------------- Generating Genesis Block -----------------"
    echo "------------------------------------------------------------"
    echo

    expand -t4 configtx.yaml > temp.yaml
    cat temp.yaml > configtx.yaml
    rm temp.yaml


    sudo chmod a+rwx $PWD
    
    #Checking if configtxgen tool is present
    which configtxgen
    if [ "$?" -ne 0 ]; then
        echo "Configtxgen tool not found. Exiting..."
        exit 1
    fi

    mkdir channel-artifacts

    set -x
    configtxgen -profile $GENESIS_PROFILE -channelID $SYS_CHANNEL -outputBlock ./channel-artifacts/genesis.block
    set +x
    if [ $? -ne 0 ]
    then
        echo "Failed to create genesis block..."
        exit 1
    fi
    

    echo
    echo
    echo
    echo
    echo "------------------------------------------------------------"
    echo "------------------ Generating Channel Txn ------------------"
    echo "------------------------------------------------------------"
    echo
    echo

    set -x
    configtxgen -profile $CHAN_PROFILE -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
    set +x
    if [ $? -ne 0 ]
    then
        echo "Failed to create channel transaction..."
        exit 1
    fi

    k=0
    # for i in "${ANCHOR_PEER_MSP_LIST[@]}"
    while [ $k -lt ${#ORG_LIST[@]} ]
    do
        i=${ORG_MSPID_LIST[$k]}
        if [ ${ANCHOR_PEER_ORG_LIST[$k]} -eq 1 ]; then
            echo
            echo
            echo
            echo "------------------------------------------------------------"
            echo "------ Generating Anchor Peers Update:$i------"
            echo "------------------------------------------------------------"
            echo
            echo

            set -x
            configtxgen -profile $CHAN_PROFILE -outputAnchorPeersUpdate ./channel-artifacts/${i}Anchors.tx -channelID $CHANNEL_NAME -asOrg ${i}
            set +x
            if [ $? -ne 0 ]
            then
                echo "Failed to update anchor peer $i..."
                exit 1
            fi
        fi
        k=`expr $k + 1`
    done

}