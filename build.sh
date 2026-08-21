#!/bin/bash
echo "=============== Building the Image ==============="
IMAGE_NAME="reactjs-app"
docker build -t $1:$IMAGE_NAME-$2 . &> /tmp/build.log || { echo "Docker build failed. Check build.log for details."; exit 1; }
echo "=============== Build Complete ==============="
echo "=============== Pushing Image to $1 ============"
docker push $1:$IMAGE_NAME-$2 &>> /tmp/push.log || { echo "Docker push failed, Check push.log for details."; exit 1;}
echo "=============== Image Pushed to repository =========="

    
