#!/bin/bash

#This function adds a new Genesis Profile in the profiles section
#It takes the different required inputs such as name and consortia
function addGenesisProfile() {
    echo
    echo -e "\nProfiles:\n" >> configtx.yaml
    read -p "Enter Genesis Block Profile Name(No spaces allowed): " GENESIS_PROFILE
    echo
    for i in ${ORDERER_MSPID_LIST[@]}
    do
        ORDERER_ORG_STRING="${ORDERER_ORG_STRING}\n\t\t\t\t- *${i}"
    done
    echo "Creating consortia:"
    echo "-----------------------"
    CONSORTIUM_MEMBERS_BOUNDARIES+=(0)
    createConsortium
    while :
    do
        read -p "Do you want to add another consortium? (y/n): " ans
        case $ans in
        "y"|"Y"|"")
            createConsortium
            ;;
        "n"|"N")
            break
            ;;
        *)
            continue
            ;;
        esac
    done
    sed -e "s/\$GENESIS_NAME/$GENESIS_PROFILE/" \
        ./templates/configtx-genesis-profile-template1.yaml >> configtx.yaml
    if [ $ORDERER_TYPE = "etcdraft" ]; then
        addRaftConsenters
    fi
    sed -e "s/\$ORDERER_ORGS/$ORDERER_ORG_STRING/" \
        -e "s/\$CONSORTIA/$CONSORTIUM_STRING/" \
        ./templates/configtx-genesis-profile-template2.yaml >> configtx.yaml
}

#This function adds a channel profile in the profiles section
#It takes inputs like the consortium used and orgs present
function addChannelProfile() {
    echo
    echo "------------------------------------------------------------------------"
    echo "----------------------- Create Channel Profile -------------------------"
    echo "------------------------------------------------------------------------"
    echo
    read -p "Enter Channel Name (Small letters only, no spaces or special characters): " CHANNEL_NAME
    echo
    read -p "Enter Channel Profile Name(No spaces): " CHAN_PROFILE
    CHANNEL_PROFILES+=($CHAN_PROFILE)
    echo
    echo "Choose consortium for the channel:-"
    counter=1
    while [ $counter -le ${#CONSORTIA[@]} ]
    do
        echo "${counter}. ${CONSORTIA[$counter-1]}"
        counter=`expr $counter + 1`
    done
    while :
    do
        read -p "Enter your choice: " choice
        if [[ ! $choice =~ ^[0-9]+$ ]]; then
            echo "Invalid"
            continue
        fi
        if [ $choice -le 0 -o $choice -ge $counter ]; then
            echo "Invalid"
            continue
        fi
        break
    done
    CHANNEL_CONSORTIUM=${CONSORTIA[$choice-1]}
    CHANNEL_ORGS_STRING+=("")
    echo
    echo "Choose orgs from Consortium \"${CHANNEL_CONSORTIUM}\" for the channel:"
    echo "----------------------------------------------------------------------------------"
    echo
    while :
    do
        temp=${CONSORTIUM_MEMBERS_BOUNDARIES[$choice-1]}
        while [ $temp -lt ${CONSORTIUM_MEMBERS_BOUNDARIES[$choice]} ]
        do
            read -p "Do you want to include ${CONSORTIUM_MEMBERS[$temp]} in the channel? (y/n): " choice_
            case $choice_ in
            "y"|"Y"|"")
                CHANNEL_ORGS_STRING[-1]="${CHANNEL_ORGS_STRING[-1]}\n\t\t\t\t- *${CONSORTIUM_MEMBERS[$temp]}"
                CHANNEL_ORGS+=(${CONSORTIUM_MEMBERS[$temp]})
                temp=`expr $temp + 1`
                ;;
            "n"|"N")
                temp=`expr $temp + 1`
                continue
                ;;
            *)
                echo "Invalid"
                continue
                ;;
            esac
        done
        if [[ -z ${CHANNEL_ORGS_STRING[-1]} ]]; then
            echo "Please choose at least one organization..."
            echo
            CHANNEL_ORGS_STRING=( ${CHANNEL_ORGS_STRING[@]:0:${#CHANNEL_ORGS_STRING[@]}-1} )
            CHANNEL_ORGS_STRING+=("")
            continue
        fi
        break
    done
    sed -e "s/\$CHANNEL_NAME/$CHAN_PROFILE/" \
        -e "s/\$CONSORTIUM/$CHANNEL_CONSORTIUM/" \
        -e "s/\$CHANNEL_ORGS/$CHANNEL_ORGS_STRING/" \
        ./templates/configtx-channel-profile-template.yaml >> configtx.yaml
    k=0
    l=0
    echo
    echo ${CHANNEL_ORGS[@]}
    CHANNEL_PEER_BOUNDARIES_LIST+=(0)
    while [ $k -lt ${#CHANNEL_ORGS[@]} ]
    do
        echo hi
        if [[ ${CHANNEL_ORGS[$k]} = ${ORG_MSPID_LIST[$l]} ]];then
            CHANNEL_ORGS_DOMAINS+=(${ORG_LIST[$l]})
            DIFF=`expr ${PEER_BOUNDARIES_LIST[$l+1]} - ${PEER_BOUNDARIES_LIST[$l]}`
            #for i in ${PEER_LIST[@]:${PEER_BOUNDARIES_LIST[$l]}:$DIFF}
            i=${PEER_BOUNDARIES_LIST[$l]}
            echo hello
            while [ $i -lt ${PEER_BOUNDARIES_LIST[$l+1]} ]
            do
                CHANNEL_PEERS+=(${PEER_LIST[$i]})
                CHANNEL_PEER_PORTS+=(${PEER_LISTEN_PORTS[$i]})
                i=`expr $i + 1`
                echo hola
            done
            CHANNEL_PEER_BOUNDARIES_LIST+=(${#CHANNEL_PEERS[@]})
            k=`expr $k + 1`
        fi
        l=`expr $l + 1`
    done
    echo "${CHANNEL_PEERS[@]}:${CHANNEL_PEER_PORTS[@]}"
    echo ${CHANNEL_PEER_BOUNDARIES_LIST[@]}
    echo ${CHANNEL_ORGS_DOMAINS[@]}
    echo ${CHANNEL_ORGS[@]}
}

#This function is used to create a consortium and append it onto 
#configtx.yaml
function createConsortium() {
    echo
    read -p "Enter Consortium Name(No spaces): " CONSORTIUM_NAME
    CONSORTIA+=($CONSORTIUM_NAME)
    echo
    echo "Choose orgs to be a part of this consortium:" 
    echo "--------------------------------------------"
    echo
    CONSORTIUM_MEMBERS_STRING=""
    while :
    do
        i=0
        while [ $i -lt ${#ORG_MSPID_LIST[@]} ]
        do
            read -p "Do you want ${ORG_MSPID_LIST[$i]} to be a part of this consortium? (y/n): " choice
            case $choice in
            "y"|"Y"|"")
                CONSORTIUM_MEMBERS_STRING="${CONSORTIUM_MEMBERS_STRING}\n\t\t\t\t\t- *${ORG_MSPID_LIST[$i]}"
                CONSORTIUM_MEMBERS+=(${ORG_MSPID_LIST[$i]})
                i=`expr $i + 1`
                ;;
            "n"|"N")
                i=`expr $i + 1`
                continue
                ;;
            *)
                echo "Invalid"
                continue
                ;;
            esac
        done
        if [[ -z ${CONSORTIUM_MEMBERS_STRING} ]]; then
            echo "Please choose at least one organization..."
            echo
            continue
        fi
        CONSORTIUM_MEMBERS_BOUNDARIES+=(${#CONSORTIUM_MEMBERS[@]})
        break
    done
    CONSORTIUM_STRING="${CONSORTIUM_STRING}\n\t\t\t${CONSORTIUM_NAME}:\n\t\t\t\tOrganizations:${CONSORTIUM_MEMBERS_STRING}"
}
