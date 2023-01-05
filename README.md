# Docker image with CUDA, CuDNN, PyTorch, OpenCV + FFMPEG support

Docker Image for NVIDIA CUDA accelerated machine learning use-cases. This container supports PyTorch, OpenCV, FFMPEG, GStreamer with CUDA 11.

## Why?

The nvidia base image for pytorch does not support OpenCV and FFMPEG by default. This Dockerfile adds additional support for OpenCV that is compiled with FFMPEG and GStreamer. This allows opening different types of videos, RTSP Streams, H264 codec etc.

## Pull

```bash
docker pull hmurari/docker-nvidia-pytorch-opencv-ffmpeg:latest
```

## Run

```bash
docker run --gpus all --ipc host --network host -it --rm hmurari/docker-nvidia-pytorch-opencv-ffmpeg:latest
```

## Build & push
If you want to build it locally & make additional changes - use the following commands.

```bash
docker build --rm -f Dockerfile -t <your-username>/docker-nvidia-pytorch-opencv-ffmpeg:latest .
docker push <your-username>/docker-nvidia-pytorch-opencv-ffmpeg:latest
```
