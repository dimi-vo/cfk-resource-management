#!/bin/bash


CP_DEMO_DIR="cp-demo"
# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

cd "$CP_DEMO_DIR" || { log "Failed to find $CP_DEMO_DIR directory"  ; exit 1; }
./scripts/stop.sh
cd ..
rm -rf cp-demo
echo "Going to delete new LDAP files"
cd cp-demo/scripts/security || exit
echo "Deleting the newly added ldap files"
rm -rf ldap_users/
mv  original-ldap_users/ ldap_users/
echo "Going back 3 dis"
echo "$pwd"
cd ../../../
cd cfk || exit
kind delete cluster
cd ..
