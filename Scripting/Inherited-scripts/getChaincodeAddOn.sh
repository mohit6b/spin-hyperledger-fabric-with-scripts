#!/bin/bash

function chaincodeAddOn() {
    echo
    while :
    do
        echo
        read -p "Do you want to install and instantiate chaincode? (y/n): " CHAINCODE_ADDON
        case $CHAINCODE_ADDON in
        "y"|"Y"|"")
            CHAINCODE_ADDON=1
            getChaincodeInfo
            ;;
        "n"|"N")
            CHAINCODE_ADDON=0
            ;;
        *)
            echo "Invalid."
            continue
            ;;
        esac
        break
    done
}

function getChaincodeInfo() {
    echo
    read -p "Enter the name of the chaincode: " CHAINCODE_NAME
    read -p "Enter chaincode language: " CHAINCODE_LANGUAGE
    for i in ${CHANNEL_PEERS[@]}
    do
        while :
        do
            read -p "Do you want to install the chaincode on $i? (y/n): " ans
            case $ans in
            "y"|"Y"|"")
                CHANNEL_CHAINCODE_BOOLEAN_LIST+=(1)
                break
                ;;
            "n"|"N")
                CHANNEL_CHAINCODE_BOOLEAN_LIST+=(0)
                break
                ;;
            *)
                echo "Invalid"
                ;;
            esac
        done
    done
    while :
    do
        echo
        echo "Enter the arguments to use for instantiating the chaincode (within square brackets): "
        read -p "Enter the arguments: " ARGS_STRING
        echo 
        ARGS_STRING="'{\"Args\":$ARGS_STRING}'"
        echo $ARGS_STRING
        echo
        read -p "Are these the given arguments? (y/n): " ans
        case $ans in
        "y"|"Y"|"")
            echo "Okay, arguments accepted"
            break
            ;;
        *)
            echo "Please enter args again..."
            ;;
        esac
    done
    echo "-------------------------------------------------------"
    echo "-------------- Create Endorsement Policy --------------"
    echo "-------------------------------------------------------"
    echo
    createEndorsementPolicy
    echo
    echo
    echo "Place the chaincode in the 'chaincode' direcory of fabric-samples"
    echo "Please provide the relative path from the 'chaincode' directory"
    echo "Example: marbles02/go"
    read -p "Enter relative path: " CHAINCODE_PATH
}

function createEndorsementPolicy() {
    POLICY="\""
    echo
    echo "Current policy: ${POLICY}"
    echo
    echo "Choose condition:"
    echo "1. OR"
    echo "2. AND"
    echo "3. OutOf"
    read -p "Enter your choice: " policy_condition
    case $policy_condition in
    1)
        if [ ${POLICY#${POLICY%?}} != "(" ]; then
            if [ ${POLICY#${POLICY%?}} != "\"" ]; then
                POLICY="${POLICY}, "
            fi
        fi
        POLICY="${POLICY}OR ("
        ;;
    2)
        if [ ${POLICY#${POLICY%?}} != "(" ]; then
            if [ ${POLICY#${POLICY%?}} != "\"" ]; then
                POLICY="${POLICY}, "
            fi
        fi
        POLICY="${POLICY}AND ("
        ;;
    3)
        read -p "Enter the required number: " req_no
        if [ ${POLICY#${POLICY%?}} != "(" ]; then
            if [ ${POLICY#${POLICY%?}} != "\"" ]; then
                POLICY="${POLICY}, "
            fi
        fi
        POLICY="${POLICY}OutOf (${req_no}"
        ;;
    *)
        echo "Invalid choice"
        createEndorsementPolicy
        return
        ;;
    esac
    echo
    while :
    do
        echo "Current policy: ${POLICY}"
        echo
        read -p "Do you want to nest a condition? (y/n): " proceed
        case $proceed in
        "y"|"Y"|"")
            createEndorsementPolicy
            ;;
        "n"|"N")
            break
            ;;
        *)
            echo "Invalid, please enter again."
            continue
            ;;
        esac
    done
    echo
    echo "Current policy: ${POLICY}"
    echo
    for j in ${CHANNEL_ORGS[@]}
    do
        for i in "member" "client" "peer" "admin"
        do
            read -p "Do you want to add ${j}.${i}? (y/n): " proceed
            case $proceed in
            "y"|"Y"|"")
                if [ ${POLICY#${POLICY%?}} != "(" ]; then
                    if [ ${POLICY#${POLICY%?}} != "\"" ]; then
                        POLICY="${POLICY}, "
                    fi
                fi
                POLICY="${POLICY}'${j}.${i}'"
                ;;
            "n"|"N")
                continue
                ;;
            *)
                echo "Considered as 'no'"
                continue
                ;;
            esac
        done
    done
    echo
    POLICY="${POLICY})\""
}