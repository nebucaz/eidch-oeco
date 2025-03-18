#!/bin/bash

# build applications
echo "compiling apps.."

cd ../eidch-issuer-agent-management
mvn clean package -Djacoco.skip=true

cd ../eidch-issuer-agent-oid4vci
mvn clean package -Djacoco.skip=true

echo -e "\n\ncompiling done, building images"
docker-compose up --build

# build images & start up
#docker-compose -f issuer-override.yml up
