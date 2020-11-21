#!/bin/bash

#These functions are used to accept the different inputs required by the 
#script to run inside of the client container. This is done as the docker container
#does not have an attached terminal input


#This function is used to accept input for which peer has to create the channel.
function promptChannelCreation() {
    #Read from user
    echo "Select the peer to create channel with: "
    k=1
    for i in ${CHANNEL_PEERS[@]}
    do
        echo "$k. $i"
        k=`expr $k + 1`
    done
    read -p "Enter your choice: " CHANNEL_CREATOR

    if [ $CHANNEL_CREATOR -gt 0 -a $CHANNEL_CREATOR -le ${#CHANNEL_PEERS[@]} ]; then
        echo "Peer has been chosen"
    else
        promptChannelCreation
    fi
}

#This function is used to accept inputs for each peer whether it is going to join the 
#channel or not
function getJoiningPeers() {
    echo "------------------------------------------------------"
    echo "---------- Select peers to join the channel ----------"
    echo "------------------------------------------------------"
    echo
    i=0
    while [ $i -lt ${#CHANNEL_PEERS[@]} ]
    do
        echo
        read -p "Do you want ${CHANNEL_PEERS[$i]} to join the channel? (y/n): " prompt
        case $prompt in
        "y"|"Y"|"")
            JOINING_PEERS+=(1)
            ;;
        "n"|"N")
            JOINING_PEERS+=(0)
            ;;
        *)
            echo "Invalid"
            continue
            ;;
        esac
        i=`expr $i + 1`
    done
}

#This function is used to choose the orderer that will be running all the required 
#commands inside the container
function chooseOrdererEndpoint() {
    echo
    echo "-----------------------------------------------------"
    echo "-------------- Choose Orderer Endpoint --------------"
    echo "-----------------------------------------------------"
    echo
    k=0
    counter=1
    while [[ $k -lt ${#ORDERER_LIST[@]} ]]
    do
        if [ ${ORDERER_ENDPOINTS_BOOLEAN[$k]} -eq 1 ]; then
            echo "$counter. ${ORDERER_LIST[$k]}"
            counter=`expr $counter + 1`
        fi
        k=`expr $k + 1`
    done
    echo "Choose orderer endpoint to take part in channel creation."
    while :
    do
        read -p "Make your choice: " choice
        if [[ ! $choice =~ ^[0-9]+$ ]] ; then
            echo "Invalid"
            continue
        fi
        if [ $choice -le 0 -o $choice -ge $counter ]; then
            echo "Invalid"
            continue
        fi
        break
    done
    k=-1
    while [ $choice -ne 0 ]
    do
        k=`expr $k + 1`
        if [ ${ORDERER_ENDPOINTS_BOOLEAN[$k]} -eq 1 ]; then
            choice=`expr $choice - 1`
        fi
    done
    CHANNEL_ORDERER=$k
}