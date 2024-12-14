#!/bin/bash

LANGUAGE=$1

if [ -z "$LANGUAGE" ]; then
    echo "Error: Language parameter is required"
    exit 1
fi

cd /opt/whanos/images/${LANGUAGE}
docker build -t whanos-${LANGUAGE}-base:latest - < Dockerfile.base 