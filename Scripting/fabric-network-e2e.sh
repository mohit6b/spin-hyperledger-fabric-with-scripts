#!/bin/bash

#This script file is used to set up a fabric network from scratch

#Setting the environment variables
export FABRIC_CFG_PATH=$PWD
export PATH=$PWD:${PWD}/../bin:$PATH
export VERBOSE=false
export SYS_CHANNEL="sys-channel"

#Exporting the required files
. ./Inherited-scripts/start.sh
. ./Inherited-scripts/createCryptoConfig.sh
. ./Inherited-scripts/utils.sh
. ./Inherited-scripts/createSignaturePolicy.sh
. ./Inherited-scripts/createConfigtxOrganizations.sh
. ./Inherited-scripts/createConfigtxMisc.sh
. ./Inherited-scripts/createImplicitMetaPolicy.sh
. ./Inherited-scripts/addOrderer.sh
. ./Inherited-scripts/createConfigtxProfiles.sh
. ./Inherited-scripts/generationScript.sh
. ./Inherited-scripts/createDockerComposeBase.sh
. ./Inherited-scripts/createDockerComposeCli.sh
. ./Inherited-scripts/createDockerComposeCA.sh
. ./Inherited-scripts/getChannelInfo.sh
. ./Inherited-scripts/getChaincodeAddOn.sh
. ./Inherited-scripts/upContainersAndChannel.sh

#Calling the appropriate functions

#./Inherited-scripts/start.sh
askProceed

#./Inherited-scripts/createCryptoConfig.sh
createOrdererOrgs
createPeerOrgs

#./Inherited-scripts/utils.sh
getOrdererPortNos
getPeerPortNos

#./Inherited-scripts/createConfigtxOrganizations.sh
addOrgsToConfigtx

#./Inherited-scripts/createConfigtxMisc.sh
addCapabilitiesandApplication
addOrderer
addChannel

#./Inherited-scripts/createConfigtxProfiles.sh
addGenesisProfile
addChannelProfile

#./Inherited-scripts/generationScript.sh
generateCerts
generateArtifacts

#./Inherited-scripts/createDockerComposeBase.sh
makeDockerComposeBase

#./Inherited-scripts/createDockerComposeCli.sh
makeDockerComposeCli

#./Inherited-scripts/createDockerComposeCA.sh
makeDockerComposeCA

#./Inherited-scripts/getChannelInfo.sh
promptChannelCreation
getJoiningPeers
chooseOrdererEndpoint

#./Inherited-scripts/getChaincodeAddOn.sh
chaincodeAddOn

#./Inherited-scripts/upContainersAndChannel.sh
startNetwork