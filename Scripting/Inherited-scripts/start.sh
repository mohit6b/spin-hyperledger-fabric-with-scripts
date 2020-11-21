#!/bin/bash

#Asking if it is okay to delete all the containers,volumes,files and artifacts
#
#Declining exits the functions
function askProceed() {
    echo "This will delete all existing docker containers,volumes,networks,artifacts,config and docker files"
    read -p "Do you want to continue? (y/n):" proceed
    case "$proceed" in
    y | Y | "")
        echo -n "Deleting"
        for i in 1 2 3 4
        do
            sleep 1
            echo -n "."
        done
        echo
        deleteAll
        ;;
    n | N)
        echo "Exiting"
        exit 1
        ;;
    *)
        echo "Invalid"
        askProceed
        ;;
    esac
}

#Function to delete all the items required to be deleted
function deleteAll() {
    echo "----------Deleting containers----------"
    docker rm -f $(docker ps -aq)
    echo "----------Deleting volumes-------------"
    docker volume rm $(docker volume ls)
    echo "----------Deleting networks------------"
    docker network rm $(docker network ls)
    rm -Rf channel-artifacts
    if [ $? -eq 0 ]; then
        echo
        echo
        echo "----------Deleting artifacts-----------"
        echo "Removed dir: ./channel-artifacts"
    fi
    echo
    echo "----------Deleting config files----------"
    rm crypto-config.yaml
    rm configtx.yaml
    rm docker-compose-cli.yaml
    rm ./base/docker-compose-base.yaml
    rm docker-compose-ca.yaml
}

function checkPrereqs() {
  # Note, we check configtxlator externally because it does not require a config file, and peer in the
  # docker image because of FAB-8551 that makes configtxlator return 'development version' in docker
  LOCAL_VERSION=$(configtxlator version | sed -ne 's/ Version: //p')
  DOCKER_IMAGE_VERSION=$(docker run --rm hyperledger/fabric-tools:$IMAGETAG peer version | sed -ne 's/ Version: //p' | head -1)

  echo "LOCAL_VERSION=$LOCAL_VERSION"
  echo "DOCKER_IMAGE_VERSION=$DOCKER_IMAGE_VERSION"

  if [ "$LOCAL_VERSION" != "$DOCKER_IMAGE_VERSION" ]; then
    echo "=================== WARNING ==================="
    echo "  Local fabric binaries and docker images are  "
    echo "  out of  sync. This may cause problems.       "
    echo "==============================================="
  fi

  for UNSUPPORTED_VERSION in $BLACKLISTED_VERSIONS; do
    echo "$LOCAL_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Local Fabric binary version of $LOCAL_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
      exit 1
    fi

    echo "$DOCKER_IMAGE_VERSION" | grep -q $UNSUPPORTED_VERSION
    if [ $? -eq 0 ]; then
      echo "ERROR! Fabric Docker image version of $DOCKER_IMAGE_VERSION does not match this newer version of BYFN and is unsupported. Either move to a later version of Fabric or checkout an earlier version of fabric-samples."
      exit 1
    fi
  done
}
