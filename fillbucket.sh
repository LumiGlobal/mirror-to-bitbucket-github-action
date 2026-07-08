#!/bin/bash

urlencode() { local string="${1}"; local strlen=${#string}; local encoded=""; local pos c o; for (( pos=0 ; pos<strlen ; pos++ )); do c=${string:$pos:1}; case "$c" in [-_.~a-zA-Z0-9] ) o="${c}" ;; * ) printf -v o '%%%02X' "'$c" ;; esac; encoded+="${o}"; done; echo "${encoded}"; }

set -o errexit
set -o pipefail
set -o nounset

trap "echo 'Missing parameter'; exit 1" INT TERM EXIT
username="$1"
password="$2"
reponame="$3"
trap - INT TERM EXIT

spacename="$username"
if [ $# -ge 4 ]; then
    spacename="$4"
fi


CURL_OPTS=(-u "$username:$password" --silent)
ENCODED_PASSWORD=$(urlencode $password)

echo "Validating BitBucket credentials..."
curl --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/user" > /dev/null || (
    echo "... failed. Most likely, the provided credentials are invalid. Terminating..."
    exit 1
)


reponame=$(echo $reponame | tr '[:upper:]' '[:lower:]')

echo "Checking if BitBucket repository \"$spacename/$reponame\" exists..."
curl "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$spacename/$reponame" | grep "error" > /dev/null && (
    echo "Failed to authenticate to BitBucket repository \"$spacename/$reponame\". API token / password might be expired."
    exit 1
)

echo $(git merge-base HEAD bitbucket/master)
echo "Pushing to remote..."
echo $(git rev-parse HEAD)
git remote add bitbucket https://"$username:$ENCODED_PASSWORD"@bitbucket.org/$spacename/$reponame.git
echo $(git branch)
echo $(git rev-list --count bitbucket/master)
echo $(git rev-list --count HEAD)
git push bitbucket master
