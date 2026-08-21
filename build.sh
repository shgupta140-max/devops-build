#!/bin/bash
echo "=============== Building the Image ==============="
IMAGE_NAME="reactjs-app"
sudo docker build -t $IMAGE_NAME . &> /tmp/build.log || { echo "Docker build failed. Check build.log for details."; exit 1; }
echo "=============== Build Complete ==============="

    
