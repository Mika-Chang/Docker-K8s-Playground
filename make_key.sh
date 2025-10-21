#!/usr/bin/bash
ssh-keygen -N '' -m PEM -t rsa -b 4096  -f ./docker-key.pem
