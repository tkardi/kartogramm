#!/bin/bash

rm -rf ./kartogramm-build || true
mkdir ./kartogramm-build

cp -r ./data ./kartogramm-build/data
cp -r ./db ./kartogramm-build/db
cp -r ./requirements.txt ./kartogramm-build/requirements.txt
cp -r ./docker/** ./kartogramm-build

cd kartogramm-build

docker build --tag localhost/kartogramm -f Dockerfile .
