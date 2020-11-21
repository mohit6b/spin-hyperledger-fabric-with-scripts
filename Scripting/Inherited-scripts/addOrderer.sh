#!/bin/bash

#This function is used to add the etcdraft part of the orderers section in 
#configtx.yaml
#It adds the different consenters required
function addRaftOrderers() {
    echo -e "\tEtcdRaft:\n\t\tConsenters:" >> configtx.yaml
    i=0
    j=1
    ORDERER_DOMAIN=${ORDERER_ORG_LIST[0]}
    while [ $i -lt ${ORDERER_BOUNDARIES_LIST[-1]} ]
    do
        if [ $i -eq ${ORDERER_BOUNDARIES_LIST[$j]} ]; then
            ORDERER_DOMAIN=${ORDERER_ORG_LIST[$j]}
            j=`expr $j + 1`
        fi
        sed -e "s/\$ORDERER_NAME/${ORDERER_LIST[$i]}/g" \
            -e "s/\$ORDERER_DOMAIN/$ORDERER_DOMAIN/g" \
            -e "s/\$ORDERER_MAIN_PORT/$ORDERER_MAIN_PORT/" \
            -e "s/\$t/\t\t\t/g" \
            ./templates/configtx-raft-template.yaml >> configtx.yaml
        i=`expr $i + 1`
    done
}

#This function is used to add the kafka part of the orderers section in 
#configtx.yaml
function addKafkaOrderers() {
    echo -e "\tKafka:\n\t\tBrokers:" >> configtx.yaml
    echo -e "\t\t\t- 127.0.0.1:9092" >> configtx.yaml
}

#This function is used to add the raft consenters for a particular 
#channel profile
#It takes inputs from the user in a y/n format for each orderer
function addRaftConsenters() {
    echo
    echo "Choose the raft consenters for this profile: "
    echo "---------------------------------------------"
    echo
    echo -e "\n\t\t\tEtcdRaft:\n\t\t\t\tConsenters:" >> configtx.yaml
    i=0
    j=1
    ORDERER_DOMAIN=${ORDERER_ORG_LIST[0]}
    while [ $i -lt ${#ORDERER_LIST[@]} ]
    do
        if [ $i -eq ${ORDERER_BOUNDARIES_LIST[$j]} ]; then
            ORDERER_DOMAIN=${ORDERER_ORG_LIST[$j]}
            j=`expr $j + 1`
        fi
        read -p "Do you want ${ORDERER_LIST[$i]} to be a consenter? (y/n)" ans
        case $ans in
        "y"|"Y"|"")
            sed -e "s/\$ORDERER_NAME/${ORDERER_LIST[$i]}/g" \
                -e "s/\$ORDERER_DOMAIN/$ORDERER_DOMAIN/g" \
                -e "s/\$ORDERER_MAIN_PORT/$ORDERER_MAIN_PORT/" \
                -e "s/\$t/\t\t\t\t/g" \
                ./templates/configtx-raft-template.yaml >> configtx.yaml
            temp_ord_list+=(${ORDERER_LIST[$i]})
            i=`expr $i + 1`
            ;;
        "n"|"N")
            i=`expr $i + 1`
            ;;
        *)
            continue
            ;;
        esac            
    done
    echo -e "\t\t\tAddresses:" >> configtx.yaml
    for i in ${temp_ord_list[@]}
    do
        echo -e "\n\t\t\t\t- $i:$ORDERER_MAIN_PORT" >> configtx.yaml
    done
}