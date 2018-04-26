#!/usr/bin/env bash

docker pull cobers/manp:drupal

docker rm -f manp
docker run -d --name manp cobers/manp:drupal
if [ -d ./web.old ]; then
  sudo rm -rf ./web.old
fi

if [ -d ./web ]; then
  mv ./web ./web.old
fi
sudo docker cp manp:/www ./web
docker stop manp
docker rm manp
