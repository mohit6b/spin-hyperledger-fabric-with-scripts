#!/bin/bash

#This file provides utility functions to create port numbers for orderers,peers and CA's
#If we want to change the algorithm to select port numbers, we can do it here

#Function to select ports for Orderers in intervals of 10
function getOrdererPortNos() {
    ORDERER_MAIN_PORT=7050
    ORDERER_PORTS+=(7060)
    for i in ${ORDERER_LIST[@]:1}
    do
        ORDERER_PORTS+=(`expr ${ORDERER_PORTS[-1]} + 10`)
    done
}

#Function to select ports for Peers in intervals of 10
function getPeerPortNos() {
    PEER_LISTEN_PORTS+=(8050)
    PEER_CC_PORTS+=(8051)
    for i in ${PEER_LIST[@]:1}
    do
        PEER_LISTEN_PORTS+=(`expr ${PEER_LISTEN_PORTS[-1]} + 10`)
        PEER_CC_PORTS+=(`expr ${PEER_LISTEN_PORTS[-1]} + 1`)
    done
}

#Function to select ports for CA's in intervals of 1000
function getCAPorts() {
    ORG_CA_PORTS+=(7054)
    for i in ${ORG_LIST[@]}
    do
        ORG_CA_PORTS+=(`expr ${ORG_CA_PORTS[-1]} + 1000`)
    done
}