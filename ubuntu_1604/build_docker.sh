#!/bin/bash

HOST_UID=$(id -u)
HOST_GID=$(id -g)

docker build --no-cache --build-arg USER_UID=$HOST_UID --build-arg USER_GID=$HOST_GID -t ubuntu_1604 .

