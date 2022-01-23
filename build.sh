#!/bin/bash

rm -r ./kartogrmm-build
mkdir ./kartogrmm-build

cp -r ./data ./kartogrmm-build/data
cp -r ./db ./kartogrmm-build/db
cp -r ./requirements.txt ./kartogrmm-build/requirements.txt
cp -r ./docker/** ./kartogrmm-build

cd kartogrmm-build

docker build --tag localhost/kartogramm -f Dockerfile .
