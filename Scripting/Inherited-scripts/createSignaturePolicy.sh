#!/bin/bash

#The functions to create Signature Policies are provided here

#This function calls createSignaturePolicy for the different Organizational Units
function getSignaturePolicy() {
    if [ $1 = "peer" ]; then
        MSPID=${ORG_MSPID_LIST[$2]}
    else
        MSPID=${ORDERER_MSPID_LIST[$2]}
    fi
    echo "----------------------------------------------------------------"
    echo "---------- Creating signature policy for $MSPID ----------"
    echo "----------------------------------------------------------------"

    echo
    for j in "Readers" "Writers" "Admins" 
    do    
        echo "$j:-"
        POLICY="\""
        createSignaturePolicy $MSPID
        POLICY="${POLICY}\""
        echo $POLICY
        echo
        echo "------------------------------------------------------"
        echo
        sed -e "s/\$TYPE/$j/" -e "s/\$RULE/$POLICY/" ./templates/configtx-sign-policies-template.yaml >> configtx.yaml
    done
}

#This function creates a Signature policy and stores it in a string
function createSignaturePolicy() {
    echo
    echo "Current policy: ${POLICY}"
    echo
    echo "Choose condition:"
    echo "1. OR"
    echo "2. AND"
    echo "3. NOutOf"
    read -p "Enter your choice: " policy_condition
    case $policy_condition in
    1)
        if [ ${POLICY#${POLICY%?}} != "(" ]; then
            if [ ${POLICY#${POLICY%?}} != "\"" ]; then
                POLICY="${POLICY}, "
            fi
        fi
        POLICY="${POLICY}OR("
        ;;
    2)
        if [ ${POLICY#${POLICY%?}} != "(" ]; then
            if [ ${POLICY#${POLICY%?}} != "\"" ]; then
                POLICY="${POLICY}, "
            fi
        fi
        POLICY="${POLICY}AND("
        ;;
    3)
        read -p "Enter the required number: " req_no
        if [ ${POLICY#${POLICY%?}} != "(" ]; then
            if [ ${POLICY#${POLICY%?}} != "\"" ]; then
                POLICY="${POLICY}, "
            fi
        fi
        POLICY="${POLICY}NOutOf(${req_no}"
        ;;
    *)
        echo "Invalid choice"
        createSignaturePolicy $1
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
            createSignaturePolicy $1
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
    for i in "member" "client" "peer" "admin"
    do
        read -p "Do you want to add ${1}.${i}? (y/n): " proceed
        case $proceed in
        "y"|"Y"|"")
            if [ ${POLICY#${POLICY%?}} != "(" ]; then
                if [ ${POLICY#${POLICY%?}} != "\"" ]; then
                    POLICY="${POLICY}, "
                fi
            fi
            POLICY="${POLICY}'${1}.${i}'"
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
    echo
    POLICY="${POLICY})"
}
