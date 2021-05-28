#!/bin/bash
set -xe

# latest commit
LATEST_COMMIT=$(git rev-parse HEAD)

# latest commit where path/to/folder1 was changed
FOLDER1_COMMIT=$(git log -1 --format=format:%H --full-diff hello-app-v1/)

# latest commit where path/to/folder2 was changed
FOLDER2_COMMIT=$(git log -1 --format=format:%H --full-diff hello-app-v2/)

if [ $FOLDER1_COMMIT = $LATEST_COMMIT ];
    then
        echo "hello-app-v1 has changed"
        sed -i "s/APP_NAME/hello-app-v1/g" .circleci/deploy.sh       
        .circleci/deploy.sh
elif [ $FOLDER2_COMMIT = $LATEST_COMMIT ];
    then
        echo "hello-app-v2 has changed"
        sed -i "s/APP_NAME/hello-app-v2/g" .circleci/deploy.sh       
        .circleci/deploy.sh
else
     echo "no folders of relevance has changed"
     circleci-agent step halt
fi