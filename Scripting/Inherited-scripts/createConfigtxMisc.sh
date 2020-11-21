#!/bin/bash

#This function adds capabilities and the application sections to configtx.yaml
#It takes inputs for the implicit meta policy required for applications
function addCapabilitiesandApplication() {
    cat ./templates/configtx-capabilities.yaml >> configtx.yaml
    for i in "Readers" "Writers" "Admins"
    do
        getImplicitMetaPolicy "Application" $i
    done
    echo -e "\tCapabilities:\n\t\t<<: *ApplicationCapabilities\n" >> configtx.yaml
}

#This function adds the channel section to configtx.yaml
#It takes inputs for the implicit meta policy required for channels
function addChannel() {
    echo -e "\nChannel: &ChannelDefaults\n\tPolicies:\n" >> configtx.yaml
    for i in "Readers" "Writers" "Admins"
    do
        getImplicitMetaPolicy "Channel" $i
    done
    echo -e "\tCapabilities:\n\t\t<<: *ChannelCapabilities\n" >> configtx.yaml
}

#This function adds the orderer section to configtx.yaml
#It takes inputs for the implicit meta policy required for orderers
#It also takes inputs for the other required info in the orderer section
function addOrderer() {
    echo 
    echo "--------------------------------------------------------------"
    echo "-------------------- Add Orderers Details --------------------"
    echo "--------------------------------------------------------------"
    echo
    while :
    do
        addOrdererEndpoints
        if [ ${#ORDERER_ENDPOINTS[@]} -eq 0 ]; then
            echo "You must select at least one endpoint."
        else
            break
        fi
    done
    for i in ${ORDERER_ENDPOINTS[@]}
    do
        ORDERER_ADDRESSES="$ORDERER_ADDRESSES\n\t\t- ${i}"
    done
    echo
    read -p "Enter Batch Timeout(in s) (provide 2): " BATCH_TIMEOUT
    read -p "Enter Max Message Count: (provide 10)" MAX_MESSAGE_COUNT
    read -p "Enter Absolute Max Bytes(in MB): (provide 99)" ABSOLUTE_MAX_BYTES
    read -p "Enter Preferred Max Bytes(in KB): (provide 512)" PREFERRED_MAX_BYTES

    sed -e "s/\$ORDERER_TYPE/$ORDERER_TYPE/" \
        -e "s/\$ORDERER_ADDRESSES/$ORDERER_ADDRESSES/" \
        -e "s/\$BATCH_TIMEOUT/$BATCH_TIMEOUT/" \
        -e "s/\$MAX_MESSAGE_COUNT/$MAX_MESSAGE_COUNT/" \
        -e "s/\$ABSOLUTE_MAX_BYTES/$ABSOLUTE_MAX_BYTES/" \
        -e "s/\$PREFERRED_MAX_BYTES/$PREFERRED_MAX_BYTES/" \
        ./templates/configtx-orderer-template.yaml >> configtx.yaml

    if [ $ORDERER_TYPE = "etcdraft" ]; then
        addRaftOrderers
    elif [ $ORDERER_TYPE = "kafka" ]; then
        addKafkaOrderers
    fi

    echo
    echo -e "\n\tOrganizations:\n\n\tPolicies:" >> configtx.yaml

    for i in "Readers" "Writers" "Admins" "BlockValidation"
    do
        getImplicitMetaPolicy "Orderer" $i
    done
}

#This function adds the orderers that will act as endpoints
function addOrdererEndpoints() {
    echo "Choose Orderer Endpoints:"
    echo "-------------------------"
    i=0
    while [ $i -lt ${ORDERER_BOUNDARIES_LIST[-1]} ]
    do
        echo
        echo "Do you want ${ORDERER_LIST[$i]}:$ORDERER_MAIN_PORT to be an endpoint?"
        read -p "Enter (y/n): " choice
        case $choice in
        "y"|"Y"|"")
            ORDERER_ENDPOINTS+=("${ORDERER_LIST[$i]}:$ORDERER_MAIN_PORT")
            ORDERER_ENDPOINTS_BOOLEAN+=(1)
            i=`expr $i + 1`
            ;;
        "n"|"N")
            ORDERER_ENDPOINTS_BOOLEAN+=(0)
            i=`expr $i + 1`
            ;;
        *)
            echo "Invalid."
            ;;
        esac
    done
}