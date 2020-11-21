#!/bin/bash

#This function creates the Implicit-Meta Policy for the parameter passed to it
function getImplicitMetaPolicy() {
    echo "------------------------------------------------------------------"
    echo "-------- Creating ImplicitMeta Policy for $1-$2 --------"
    echo "------------------------------------------------------------------"
    echo
    echo -e "\t\t${2}:\n\t\t\tType: ImplicitMeta" >> configtx.yaml
    getRole
    getRule
    echo -e "\t\t\tRule: \"${RULE} ${ROLE}\"\n" >> configtx.yaml
}

#This function displays a list of available organization roles and takes input
function getRole() {
    echo "Create Rule:"
    echo "--------------------------"
    echo
    echo "Select Role:"
    echo "1. Readers"
    echo "2. Writers"
    echo "3. Admin"
    echo 
    #Infinite loop till the user enters a valid choice
    while :
    do
        read -p "Enter your choice:" ROLE
        case $ROLE in
        1)
            ROLE="Readers"
            break
            ;;
        2)
            ROLE="Writers"
            break
            ;;
        3)
            ROLE="Admins"
            break
            ;;
        *)
            echo "Invalid Choice."
            ;;
        esac
    done
}

#This function displays a list of available rule options and takes input
function getRule() {
    echo
    echo "Select Rule:"
    echo "1. ANY"
    echo "2. ALL"
    echo "3. MAJORITY"
    echo 
    while :
    do
        read -p "Enter your choice:" RULE
        case $RULE in
        1)
            RULE="ANY"
            break
            ;;
        2)
            RULE="ALL"
            break
            ;;
        3)
            RULE="MAJORITY"
            break
            ;;
        *)
            echo "Invalid Choice."
            ;;
        esac
    done
}
