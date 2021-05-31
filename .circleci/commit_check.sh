#!/bin/bash
set -xe

LATEST_COMMIT=$(git rev-parse HEAD)

FOLDER1_COMMIT=$(git log -1 --format=format:%H --full-diff hello-app-v1/)

FOLDER2_COMMIT=$(git log -1 --format=format:%H --full-diff hello-app-v2/)

if [ $FOLDER1_COMMIT = $LATEST_COMMIT ];
    then
        echo "hello-app-v1 has changed"
        sed -i "s/APP_NAME/hello-app-v1/g" .circleci/build.sh
        APP_NAME="hello-app-v1"
        export APP_NAME
        .circleci/build.sh
elif [ $FOLDER2_COMMIT = $LATEST_COMMIT ];
    then
        echo "hello-app-v2 has changed"
        sed -i "s/APP_NAME/hello-app-v2/g" .circleci/build.sh
        APP_NAME="hello-app-v2"
        export APP_NAME
        .circleci/build.sh
else
        echo "no folders of relevance has changed"
        circleci-agent step halt
fi