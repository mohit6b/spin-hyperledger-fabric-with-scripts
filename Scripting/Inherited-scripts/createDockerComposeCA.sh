#!/bin/bash

#This function obtains the private keys of each peer org
function getPrivateKeys() {
    for i in ${ORG_LIST[@]}
    do
        ORG_PRIV_KEYS+=($(cd crypto/peerOrganizations/${i}/ca && ls *_sk))
    done
}

#This function creates the CA's required by each org
#It creates a different CA for each org
function makeDockerComposeCA() {
    getCAPorts
    getPrivateKeys

    echo -e "version: '2'\n\nnetworks:\n  $NETWORK_NAME:\n\nservices:" >> docker-compose-ca.yaml
    i=0
    while [ $i -lt ${#ORG_LIST[@]} ]
    do
        sed -e "s/\$ORG_NAME/${ORG_MSPID_LIST[$i]}/g" \
            -e "s/\$ORG_DOMAIN/${ORG_LIST[$i]}/g" \
            -e "s/\$ORG_PRIVATE_KEY/${ORG_PRIV_KEYS[$i]}/g" \
            -e "s/\$ORG_CA_PORT/${ORG_CA_PORTS[$i]}/g" \
            -e "s/\$NETWORK_NAME/$NETWORK_NAME/g" \
            ./templates/docker-compose-ca-template.yaml >> docker-compose-ca.yaml
        i=`expr $i + 1`
    done
}