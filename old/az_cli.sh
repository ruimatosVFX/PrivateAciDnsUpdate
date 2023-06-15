#!/bin/bash

az --version

echo "Log in with Identity"

az login --identity

ACI_IP=$(az container show --name $ACI_INSTANCE_NAME --resource-group $RESOURCE_GROUP --query ipAddress.ip --output tsv)

echo $ACI_IP

if [ $(az network private-dns record-set a show --name $A_RECORD_NAME --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME) = false ]; then
    echo "DNS Record does not exist. Will create it.";
    az network private-dns record-set a create --name $A_RECORD_NAME --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME --set aRecords[0].ipv4Address=$ACI_IP --ttl 60;
else
    echo "DNSRecord updated";
    az network private-dns record-set a update --name $A_RECORD_NAME --resource-group $RESOURCE_GROUP --zone-name $DNS_ZONE_NAME --set aRecords[0].ipv4Address=$ACI_IP;
fi

echo "Done"
