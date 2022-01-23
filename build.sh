#!/bin/bash

rm -r ./kartogramm-build
mkdir ./kartogramm-build

cp -r ./data ./kartogramm-build/data
cp -r ./db ./kartogramm-build/db
cp -r ./requirements.txt ./kartogramm-build/requirements.txt
cp -r ./docker/** ./kartogramm-build

cd kartogrmm-build

docker build --tag localhost/kartogramm -f Dockerfile .
