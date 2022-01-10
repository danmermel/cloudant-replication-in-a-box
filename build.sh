#!/bin/bash
#this script has to run after all other terraform actions have happened. 

#first copy the terraform output to a creds file
cd terraform
terraform output -json > ../creds.json
cd ..

DB_NAME="users"
export CR_NAME=`cat creds.json | jq '.cr_id.value' | sed 's/"//g'`
export RG_NAME=`cat creds.json | jq '.resource_group_name.value' | sed 's/"//g'`

#create a db in dallas
export COUCH_URL=`cat creds.json | jq '.cloudantDallas_credentials.value.url' | sed 's/"//g'`
export IAM_API_KEY=`cat creds.json | jq '.cloudantDallas_credentials.value.apikey' | sed 's/"//g'`
echo "Creating a DB in Dallas if it does not already exist..."
ccurl -X PUT "/$DB_NAME"

echo "creating the replicator db..."
ccurl -X PUT /_replicator

#create a db in London
export COUCH_URL=`cat creds.json | jq '.cloudantLondon_credentials.value.url' | sed 's/"//g'`
export IAM_API_KEY=`cat creds.json | jq '.cloudantLondon_credentials.value.apikey' | sed 's/"//g'`
echo "Creating a DB in London if it does not already exist..."
ccurl -X PUT "/$DB_NAME"

echo "creating the replicator db..."
ccurl -X PUT /_replicator

#run replication monitors
#copy creds to monitoring
cp creds.json monitoring/

#make sure your account is targeting a resource group
ibmcloud target -g "$RG_NAME" 

#let docker access your ibm container registry
ibmcloud cr login

#go into each folder, build the docker images and push to container registry
echo "Building docker image..."
cd monitoring
docker build -t monitor .
docker tag monitor "uk.icr.io/$CR_NAME/monitor:latest"
docker push "uk.icr.io/$CR_NAME/monitor:latest"

#create a Code Engine project
echo "Creating CE project..."
ibmcloud ce project create --name replicationmonitor
ibmcloud ce project select -n replicationmonitor

#create the registry access key.. we need data from the creds file
CONTKEY_PASS=`cat creds.json | jq '.containerKey.value' | sed 's/"//g'`
ibmcloud ce registry create --name contkey --server uk.icr.io --password "${CONTKEY_PASS}"

#create a CE job for monitor
echo "Creating London CE job..."
ibmcloud ce job create --name londonmonitor --image "uk.icr.io/$CR_NAME/monitor" --cpu 0.125 --memory 0.25G --registry-secret contkey

## tell it to run every minute
echo "Creating London cron subscription..."
ibmcloud ce sub cron create --name london-cron-sub --destination londonmonitor --data "{\"SOURCE\":\"London\", \"TARGET\": \"Dallas\", \"DB_NAME\": \"${DB_NAME}\" }" --schedule '* * * * *' --destination-type job


## do it again for dallas
#create a CE job for monitor
echo "Creating Dallas CE job..."
ibmcloud ce job create --name dallasmonitor --image "uk.icr.io/$CR_NAME/monitor" --cpu 0.125 --memory 0.25G --registry-secret contkey

## tell it to run every minute
echo "Creating Dallas cron subscription..."
ibmcloud ce sub cron create --name dallas-cron-sub --destination dallasmonitor --data "{\"SOURCE\":\"Dallas\", \"TARGET\": \"London\", \"DB_NAME\": \"${DB_NAME}\" }" --schedule '* * * * *' --destination-type job
