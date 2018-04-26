#!/usr/bin/env bash

docker pull cobers/manp:drupal

docker rm -f drupal
docker run -d --name drupal cobers/manp:drupal
if [ -d ./web.old ]; then
  sudo rm -rf ./web.old
fi

if [ -d ./web ]; then
  mv ./web ./web.old
fi
sudo docker cp drupal:/www ./web
docker stop drupal
docker rm drupal
