#!/bin/bash

set -e

INI=$1
WORKING=$(pwd)/working/
OUTPUT=$(pwd)/output/

echo "Creating deployment using variables in $INI"

while IFS='= ' read var val
do
    if [[ $var == \[*] ]]
    then
        section=$var
    elif [[ $val ]]
    then
        declare "$var$section=$val"
	echo "    $var$section=$val"
    fi
done < $INI


echo "Cloning $repo to ${WORKING}known..."

mkdir $WORKING
git clone $repo ${WORKING}known
rm -rf ${WORKING}known/.git

cd ${WORKING}known
composer install --no-dev --prefer-dist --ignore-platform-reqs
echo "revision = \"$(git rev-parse --short HEAD)\"" >> version.known
cd ../..


echo "Loading build details from ${WORKING}known/version.known"
while IFS='= ' read var val
do
    if [[ $var == \[*] ]]
    then
        section=$var
    elif [[ $val ]]
    then
	val=$(echo $val | sed 's/"//g')
        declare "$var$section=$val"
        echo "    $var$section=$val"
    fi
done < ${WORKING}known/version.known

filename=$(echo $filename | sed "s/\$version/${version}/g")
filename=$(echo $filename | sed "s/\$build/${build}/g")
filename=$(echo $filename | sed "s/'//g")

mkdir $OUTPUT

cd ${WORKING}known/
echo "Building $filename.zip in $OUTPUT"
zip -r ${OUTPUT}$filename.zip *
echo "Building $filename.tgz in $OUTPUT"
tar -cvzf ${OUTPUT}$filename.tgz *
cd -

echo "Creating signatures..."
cd ${OUTPUT}
sha256sum $filename.zip > $filename.zip.sha256
sha256sum $filename.tgz > $filename.tgz.sha256

echo "Signing..."
gpg -u 0x$key --detach-sign -o $filename.zip.sha256.gpg $filename.zip.sha256
gpg -u 0x$key --detach-sign -o $filename.tgz.sha256.gpg $filename.tgz.sha256

cd -

echo "Cleaning up..."
rm -rf "${WORKING}known"


