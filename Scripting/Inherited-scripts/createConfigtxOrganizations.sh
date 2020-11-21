#!/bin/bash

#This file takes inputs for the 'Organizations:' part of configtx.yaml and appends it

#This function is used to add the anchor peers for each of the peerOrgs
function addAnchorPeers() {
    echo "----------------------------------------------------------------"
    echo "----------- Select anchor peer for ${ORG_LIST[$1]} -----------"
    echo "----------------------------------------------------------------"
    echo 
    z=`expr $1 + 1`
    m=${PEER_BOUNDARIES_LIST[$1]}
    counter=0

    #Loop to display the list
    while [ ${m} -lt ${PEER_BOUNDARIES_LIST[$z]} ]
    do
        if [ ${ANCHOR_PEER_LIST[$m]} -eq 0 ]; then
            counter=`expr $counter + 1`
            echo "${counter}. ${PEER_LIST[$m]}"
        fi
        m=`expr $m + 1`
    done
    counter=`expr $counter + 1`
    echo "${counter}. Finish"
    
    #Loop that goes on infinitely till valid choice is provided
    while :
    do
        read -p "Make your choice: " choice
        if [[ ! $choice =~ ^[0-9]+$ ]] ; then
            echo "Invalid"
            continue
        fi
        if (( "$choice" <= "$counter" && "$choice" > "0" )); then
            break
        fi
        echo "Invalid"
    done

    if [ $choice = $counter ]; then
        echo
        echo "Anchor peers for ${ORG_LIST[$1]} have been selected."
        echo
        return
    fi
    
    m=${PEER_BOUNDARIES_LIST[$1]}
    counter=1
    while [ $m -lt ${PEER_BOUNDARIES_LIST[$z]} ]
    do
        if [ ${ANCHOR_PEER_LIST[$m]} -eq 1 ]; then
            m=`expr $m + 1`
            continue
        fi
        if [ $counter = $choice ]; then
            ANCHOR_PEER_LIST[$m]=1
            if [ ${ANCHOR_PEER_ORG_LIST[$1]} -eq 0 ]; then
                ANCHOR_PEER_ORG_LIST[$1]=1
                echo -ne "\n\t\tAnchorPeers:" >>configtx.yaml
            fi
            sed -e "s/\$HOSTNAME/${PEER_LIST[$m]}/" \
                -e "s/\$PORT_NUMBER/${PEER_LISTEN_PORTS[$m]}/" \
                ./templates/configtx-anchor-peer-template.yaml >> configtx.yaml
            addAnchorPeers $1
            return
        fi
        m=`expr $m + 1`
        counter=`expr $counter + 1`
    done
}

#This function adds the entire 'Organizations' section of configtx.yaml from scratch
#It accepts inputs for each of the required parameters
#Some parameters are reused from crypto-config.yaml
function addOrgsToConfigtx() {
    echo "Organizations:" >> configtx.yaml
    k=0
    for l in ${ORDERER_ORG_LIST[@]}
    do
        sed -e "s/\$MSPID/${ORDERER_MSPID_LIST[$k]}/g" \
            -e "s/\$DOMAIN/$l/" \
            -e "s/\$ORG_TYPE/ordererOrganizations/" \
            ./templates/configtx-org-template.yaml >> configtx.yaml

        echo -n "Policies:" >> configtx.yaml
        getSignaturePolicy "orderer" $k  
        k=`expr $k + 1` 
    done

    k=0
    m=0
    for l in ${ORG_LIST[@]}
    do
        sed -e "s/\$MSPID/${ORG_MSPID_LIST[$k]}/g" \
            -e "s/\$DOMAIN/$l/" \
            -e "s/\$ORG_TYPE/peerOrganizations/" \
            ./templates/configtx-org-template.yaml >> configtx.yaml

        echo -n "Policies:" >> configtx.yaml
        getSignaturePolicy "peer" $k

        addAnchorPeers $k
        k=`expr $k + 1`
    done    
}
