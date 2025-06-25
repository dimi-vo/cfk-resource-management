#!/bin/bash

OS=$(uname -s)

if  ([ "$OS" == "Darwin" ] || (grep -q "host.docker.internal" /etc/hosts))
then
    echo "✔︎ no need to update /etc/hosts"
else
    echo "You may be asked to add a password (sudo command executed)"
    sudo sh -c 'echo "$(dig +short `hostname` | head -n1) host.docker.internal"  >> /etc/hosts'
    echo "✔︎ /etc/hosts updated"
fi

rm -rf cp-demo
git clone https://github.com/confluentinc/cp-demo
echo "✔︎ cp-demo cloned"

cd cp-demo || exit
git checkout 7.5.6-post
echo "✔︎ CP 7.5.6 defined"

if  [ "$OS" == "Linux" ]
then
    sed -i 's/,dns:localhost/,dns:localhost,dns:host.docker.internal/g' scripts/security/certs-create-per-user.sh
    sed -i 's/"DNS.4 = kafka2"/"DNS.4 = kafka2" "DNS.5 = host.docker.internal"/g' scripts/security/certs-create-per-user.sh
else
    sed -i '' 's/,dns:localhost/,dns:localhost,dns:host.docker.internal/g' scripts/security/certs-create-per-user.sh
    sed -i '' 's/"DNS.4 = kafka2"/"DNS.4 = kafka2" "DNS.5 = host.docker.internal"/g' scripts/security/certs-create-per-user.sh
fi

echo "Moving to directory that contains ldap files"
cd ./scripts/security || exit
echo "Renaming original folder to ignore files"
mv ldap_users/ original-ldap_users/
echo "Adding new files"
cp -r ../../../data/security/ldap_users/ ldap_users
cd - || exit
echo "Files were replaced"

CLEAN=true C3_KSQLDB_HTTPS=false VIZ=false ./scripts/start.sh

cd ..
