#!/bin/bash

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


echo "Validating BitBucket credentials..."
curl --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/user" > /dev/null || (
    echo "... failed. Most likely, the provided credentials are invalid. Terminating..."
    exit 1
)


reponame=$(echo $reponame | tr '[:upper:]' '[:lower:]')

echo "Checking if BitBucket repository \"$spacename/$reponame\" exists..."
curl "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$spacename/$reponame" | grep "error" > /dev/null && (
    echo "BitBucket repository \"$spacename/$reponame\" does NOT exist, creating it..."
    curl -X POST --fail "${CURL_OPTS[@]}" "https://api.bitbucket.org/2.0/repositories/$spacename/$reponame" -H "Content-Type: application/json" -d '{"scm": "git", "is_private": "true"}' > /dev/null
)

echo "Pushing to remote..."
git remote add bitbucket https://"$username:$password"@bitbucket.org/$spacename/$reponame.git
git fetch --unshallow bitbucket 
git push -f bitbucket master

# git checkout -b newBranch bitbucket/master
# git config --global user.email "kevin@luminews.my"
# git config --global user.name "Kevin Sia"
# git branch
# git merge master --allow-unrelated-histories
# git diff --check
