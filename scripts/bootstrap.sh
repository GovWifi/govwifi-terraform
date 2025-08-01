#!/bin/bash

# Usage
# Call this script with one argument (NEW_ENV_NAME) consisting of only lowercase alphabetic characters
# from the govwifi-terraform directory top level.
# Example: scripts/myscript.sh recovery

# Purpose
# This script will
#   check the env var PASSWORD_STORE_DIR is set and exit if false
#   create new directories in govwifi-terraform & govwifi-build for a user supplied environment name
#   copy staging files to the directories (correctly excluding .terraform directory structure)
#   modify the files to match the new environment name
#   modify the Makefile to add the new environment and preserve the previous version temporarily
#   generate a key pair and store in govwifi-build repo secrets
#   insert public key and key names into terraform files for the new environment
#   uncomments 2 x secrets-manager.tf file code blocks
#   creates intitial DNS entry and outputs nameservers for production incorporation to file: ns-records.json
#   manipulates ns-records.json to insert real ns records into Production domain wifi.service.gov.uk
#   creates access logs' buckets
#   creates state bucket
#   initialise terraform


# Ensure the correct number of arguments are passed

if [ "$#" -ne 1 ]; then
    printf "Usage: $0 NEW_ENV_NAME\n\n"
    exit 1
fi

# Check if the input is alphabetic and no uppercase letters

if ! [[ $1 =~ ^[a-z]+$ ]]; then
    printf "Error: The argument must be a single word consisting of only lowercase characters\n\n"
    exit 1
fi

# Assign the provided parameter to NEW_ENV_NAME variable

NEW_ENV_NAME=$1
printf "New environment name is: $NEW_ENV_NAME\n\n"
while true; do
    read -p "Is this correct? (y/n): " yn
    case $yn in
        [Yy]* ) printf "Confirmed. Proceeding...\n\n"; break;;  # Continue the script if confirmed
        [Nn]* ) printf "Please set the correct environment name\n\n"; exit 1;;  # Exit if not confirmed
        * ) printf "Please answer y or n\n";;  # Repeat the prompt if input is invalid
    esac
done

BUILD_REPO="../govwifi-build"
TERRAFORM_REPO="../govwifi-terraform"

# New environment in build, root
BUILD_PATH="$BUILD_REPO/non-encrypted/secrets-to-copy/govwifi"

# New environment in terraform, root
TERRAFORM_PATH="$TERRAFORM_REPO/govwifi"

# Source env directory in build repo
BUILD_SOURCE="$BUILD_PATH/staging"

# New env directory in build repo
BUILD_DESTINATION="$BUILD_PATH/$NEW_ENV_NAME"

# new env directory in build for certs
BUILD_CERTS_SOURCE="$BUILD_REPO/passwords/certs/staging"
BUILD_CERTS_DESTINATION="$BUILD_REPO/passwords/certs/$NEW_ENV_NAME"

# Source env directory in terraform repo
TERRAFORM_SOURCE="$TERRAFORM_PATH/staging"

# New env directory in terraform repo
TERRAFORM_DESTINATION="$TERRAFORM_PATH/$NEW_ENV_NAME"

# Check if PASSWORD_STORE_DIR is set

if [ -z "$PASSWORD_STORE_DIR" ]; then
    printf "The environment variable PASSWORD_STORE_DIR is not set\n\n"
    read -p "Please set the environment variable PASSWORD_STORE_DIR and rerun the script. Press any key to exit"
    exit 1
else
    printf "PASSWORD_STORE_DIR is set to '$PASSWORD_STORE_DIR'. Continuing with the script...\n\n"
fi

# Set path to keys inside secrets
SSH_KEYS_SECRET_PATH="keys"

# Create key pair, $KEY_PATH includes path and key name

KEY_NAME="govwifi-${NEW_ENV_NAME}-bastion-$(date +%Y%m%d)"
KEY_PATH="${BUILD_REPO}/${KEY_NAME}"
KEY_PUB_NAME="${KEY_NAME}.pub"
PASSPHRASE=""

ssh-keygen -t rsa -b 4096 -f $KEY_PATH -C "govwifi-developers@digital.cabinet-office.gov.uk"  -o -a 100 -P "$(echo -n "$PASSPHRASE\n" | sed 's/\\n/\n/')"
if [ $? -eq 0 ]; then
    printf "New key pair has been generated and saved in ${BUILD_REPO}\n"
else
    printf "Error: Failed to generate new key pair\n\n"
fi

# Encrypt keys and add to secrets

printf "\n\n"
pass insert -m ${SSH_KEYS_SECRET_PATH}/${KEY_NAME} < ${KEY_PATH}

if [ $? -eq 0 ]; then
    printf "key ${KEY_PATH} added\n\n"
else
    printf "Error: Failed to add new key\n\n"
fi

pass insert -m ${SSH_KEYS_SECRET_PATH}/${KEY_PUB_NAME} < ${BUILD_REPO}/${KEY_PUB_NAME}

if [ $? -eq 0 ]; then
    printf "key ${KEY_PATH}.pub added\n\n"
    rm ${KEY_PATH} ${BUILD_REPO}/${KEY_PUB_NAME}
else
    printf "Error: Failed to add new pub key\n\n"
fi

pass find ${NEW_ENV_NAME}

printf "\n\n"

# Check if new environment exists and prompt to overwrite

if [ -d "$TERRAFORM_DESTINATION" ]; then
    read -p "Directory $TERRAFORM_DESTINATION exists. Do you want to overwrite existing files? (y/n): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        printf "Overwriting files in $TERRAFORM_DESTINATION\n\n"
    else
        printf "New environment creation canceled\n\n"
        exit 1
    fi
else
    printf "Directory $TERRAFORM_DESTINATION does not exist. Creating\n\n"
fi

# Create the build destination directory if it doesn't exist

if [ ! -d "$BUILD_DESTINATION" ]; then
    mkdir -p "$BUILD_DESTINATION"
fi

# Copy the secrets path to a new environment directory with the specified name

printf "Working in %s \n\n" $BUILD_PATH
cp -Rp $BUILD_SOURCE/* $BUILD_DESTINATION
printf "Done\n\n"

# copy the certs from staging to the new environment
printf "Working in %s \n\n" $BUILD_PATH
mkdir "$BUILD_CERTS_DESTINATION"
cp -ra "$BUILD_CERTS_SOURCE/." "$BUILD_CERTS_DESTINATION"
printf "Copy Certs Done\n\n"

# Loop through the environment files and replace 'govwifi' with the new environment nam

printf "Updating environment references in $BUILD_DESTINATION file\n\n"

for filename in "$BUILD_DESTINATION"/* ; do
    sed -i '' "s/[sS]taging/$NEW_ENV_NAME/g" $filename
done

# Create the terraform destination directory if it doesn't exist

if [ ! -d "$TERRAFORM_DESTINATION" ]; then
    mkdir -p "$TERRAFORM_DESTINATION"
fi

# Copy staging to a new environment directory with the specified name

printf "Working in $TERRAFORM_PATH\n\n"
cp -Rp $TERRAFORM_SOURCE/* $TERRAFORM_DESTINATION
rm -rf $TERRAFORM_DESTINATION.
printf "Done\n\n"

# Loop through the recovery files and replace 'govwifi' with the new environment nam

printf "Updating environment references in $TERRAFORM_DESTINATION file\n\n"

for filename in "$TERRAFORM_DESTINATION"/* ; do
    sed -i '' "s/[sS]taging/$NEW_ENV_NAME/g" $filename
done

# Inject new env into Makefile above "wifi:"

cat $TERRAFORM_REPO/Makefile | \
sed "s/^wifi:/${NEW_ENV_NAME}:\n	\$(eval export DEPLOY_ENV=${NEW_ENV_NAME})\n	\$(eval export REPO=${NEW_ENV_NAME})\nwifi:/g" > $TERRAFORM_REPO/Makefile.tmp
if [ $? -eq 0 ]; then
    printf "New Makefile has been updated with ${NEW_ENV_NAME} environment\n\n"
    mv $TERRAFORM_REPO/Makefile $TERRAFORM_REPO/Makefile.old
    mv $TERRAFORM_REPO/Makefile.tmp $TERRAFORM_REPO/Makefile
else
    printf "ERROR: Failed to modify Makefile with new environment\n\n"
fi

# Modify dublin.tf and london.tf with key name

sed -i '' "s/$NEW_ENV_NAME-bastion-[0-9]*/$KEY_NAME/g" $TERRAFORM_DESTINATION/dublin.tf $TERRAFORM_DESTINATION/london.tf

if [ $? -eq 0 ]; then
    printf "london.tf and dublin.tf modified with new key name\n\n"
else
    printf "Error: Failed to modify files\n\n"
fi

# Read and insert public key into dublin.tf and dublin.tf

GOVWIFI_BASTION_KEY_PUB=`cat ${KEY_PATH}.pub`
sed -i '' "s|govwifi_bastion_key_pub.*|govwifi_bastion_key_pub  = \"$GOVWIFI_BASTION_KEY_PUB\"|" $TERRAFORM_DESTINATION/dublin.tf $TERRAFORM_DESTINATION/london.tf

if [ $? -eq 0 ]; then
    printf "New public key inserted\n\n"
else
    printf "Error: Failed to insert new public key\n\n"
fi

# Correct variables.tf key name

sed -i '' "s|$NEW_ENV_NAME-ec2-instances-[0-9]*|$KEY_NAME|" $TERRAFORM_DESTINATION/variables.tf
if [ $? -eq 0 ]; then
    printf "New key name updated in variables.tf\n\n"
else
    printf "Error: Failed to update key name in variables.tf\n\n"
fi

# Auto-generate DB secrets - uncommenting secrets files

TARGET_FILE="govwifi-admin/secrets-manager.tf"

# Patterns to identify the block to uncomment
START_PATTERN="## COMMENT BELOW IN IF CREATING A NEW ENVIRONMENT FROM SCRATCH"  # Marks the beginning of the block
END_PATTERN="## END CREATING A NEW ENVIRONMENT FROM SCRATCH"      # Marks the end of the block

# Use sed to uncomment the lines in the specified block
sed -i '' "/$START_PATTERN/,/$END_PATTERN/ s/^#//" "$TARGET_FILE"

echo "Uncommented block between '$START_PATTERN' and '$END_PATTERN' in $TARGET_FILE"

TARGET_FILE="govwifi-backend/secrets-manager.tf"

# Patterns to identify the block to uncomment
START_PATTERN="# COMMENT BELOW IN IF CREATING A NEW ENVIRONMENT FROM SCRATCH"  # Marks the beginning of the block
END_PATTERN="## END CREATING A NEW ENVIRONMENT FROM SCRATCH"      # Marks the end of the block

# Use sed to uncomment the lines in the specified block
sed -i '' "/$START_PATTERN/,/$END_PATTERN/ s/^#//" "$TARGET_FILE"

echo "Uncommented block between '$START_PATTERN' and '$END_PATTERN' in $TARGET_FILE"


# DNS Setup

printf "Creating initial DNS entry, you'll need to copy the NameServers lines\n\n"
gds-cli aws govwifi-${NEW_ENV_NAME} -- aws route53 create-hosted-zone --name "${NEW_ENV_NAME}.wifi.service.gov.uk" --hosted-zone-config "Comment=\"\",PrivateZone=false" --caller-reference "govwifi-$(date)" | jq -r '.DelegationSet.NameServers[]' > $TERRAFORM_REPO/ns-records.json

# Extract NS values and dynamically create ns-records.json

JSON_INPUT=$(cat <<EOF
{
    "Location": "https://route53.amazonaws.com/2013-04-01/hostedzone/Z008453713FV9IMQG86IV",
    "HostedZone": {
        "Id": "/hostedzone/Z008453713FV9IMQG86IV",
        "Name": "${NEW_ENV_NAME}.wifi.service.gov.uk.",
        "CallerReference": "govwifi-Fri 15 Nov 2024 16:13:12 GMT",
        "Config": {
            "Comment": "",
            "PrivateZone": false
        },
        "ResourceRecordSetCount": 2
    },
    "ChangeInfo": {
        "Id": "/change/C03932172NA3IPGZ0HVTN",
        "Status": "PENDING",
        "SubmittedAt": "2024-11-15T16:13:14.286000+00:00"
    },
    "DelegationSet": {
        "NameServers": [
            "ns-975.awsdns-57.net",
            "ns-2034.awsdns-62.co.uk",
            "ns-1040.awsdns-02.org",
            "ns-64.awsdns-08.com"
        ]
    }
}
EOF
)

# Use jq to extract NS records
NS_RECORDS=$(echo "$JSON_INPUT" | jq -r '.DelegationSet.NameServers[]')

# Create the JSON payload

pwd
cat <<EOF > ns-records.json
{
  "Comment": "Add NS records for ${NEW_ENV_NAME}.wifi.service.gov.uk",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${NEW_ENV_NAME}.wifi.service.gov.uk.",
        "Type": "NS",
        "TTL": 172800,
        "ResourceRecords": [
EOF

# Add each NS value as a separate ResourceRecord

for ns in $NS_RECORDS; do
  echo "          {\"Value\": \"$ns\"}," >> ns-records.json
done

# Remove the trailing comma from the last record and close the JSON payload file

sed -i '' '$ s/,$//' ns-records.json
cat <<EOF >> ns-records.json
        ]
      }
    }
  ]
}
EOF

printf "ns-records.json has been generated successfully!\n\n"

# Inject ns records into our wifi.service.gov.uk domain

HOSTED_ZONE_ID=`gds-cli aws govwifi -- aws route53 list-hosted-zones-by-name --dns-name wifi.service.gov.uk | jq -r '.HostedZones[].Id'`

gds-cli aws govwifi -- aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch file://ns-records.json

if [ $? -eq 0 ]; then
    printf "NS records inserted into Production successfully\n\n"
else
    printf "Error: Failed to insert new NS records into Productioney\n\n"
fi


# Phew! Now let's create some required buckets

# S3 Access Logs buckets
gds-cli aws govwifi-${NEW_ENV_NAME} -- aws s3api create-bucket --bucket govwifi-${NEW_ENV_NAME}-london-accesslogs --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2
gds-cli aws govwifi-${NEW_ENV_NAME} -- aws s3api create-bucket --bucket govwifi-${NEW_ENV_NAME}-dublin-accesslogs --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1

# Remote State bucket
gds-cli aws govwifi-${NEW_ENV_NAME} -- aws s3api create-bucket --bucket govwifi-${NEW_ENV_NAME}-tfstate-eu-west-2 --region eu-west-2 --create-bucket-configuration LocationConstraint=eu-west-2

# Initialise terraform
cd ${TERRAFORM_REPO}
gds-cli aws govwifi-${NEW_ENV_NAME} -- make ${NEW_ENV_NAME} init-backend

# To import state, this command might suffice:
# gds-cli aws govwifi-${NEW_ENV_NAME} -- make ${NEW_ENV_NAME} terraform terraform_cmd="import module.tfstate.aws_s3_bucket.state_bucket govwifi-${NEW_ENV_NAME}-tfstate-eu-west-2"

# Let's clean up
cd ${TERRAFORM_REPO}
rm Makefile.old

printf "\n\nscript finished\n\n"
