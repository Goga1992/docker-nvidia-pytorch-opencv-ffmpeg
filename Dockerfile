FROM nvidia/cuda:11.3.0-cudnn8-devel-ubuntu20.04

ARG CUDA_VERSION=11.3.0

LABEL maintainer="https://github.com/visionify"

ARG PYTHON_VERSION=3.8
ARG OPENCV_VERSION=4.6.0

# Needed for string substitution
SHELL ["/bin/bash", "-c"]

# https://techoverflow.net/2019/05/18/how-to-fix-configuring-tzdata-interactive-input-when-building-docker-images/
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=US/Mountain

# ENV LD_LIBRARY_PATH /usr/local/${CUDA}/compat:$LD_LIBRARY_PATH

RUN apt-get update -qq --fix-missing && \
    apt-get install -y --no-install-recommends software-properties-common && \
    apt-get install -y python${PYTHON_VERSION} python3-pip python3-dev python3-numpy

ENV PYTHONPATH="/usr/lib/python${PYTHON_VERSION}/site-packages:/usr/local/lib/python${PYTHON_VERSION}/site-packages"

RUN CUDA_PATH=(/usr/local/cuda-*) && \
    CUDA=`basename $CUDA_PATH` && \
    echo "$CUDA_PATH/compat" >> /etc/ld.so.conf.d/${CUDA/./-}.conf && \
    ldconfig

# Install all dependencies for OpenCV
RUN apt-get -y update -qq --fix-missing && \
    apt-get -y install --no-install-recommends \
        unzip \
        cmake \
        pkg-config \
        apt-utils \
        build-essential \
        gfortran \
        qt5-default \
        checkinstall \
        ffmpeg \
        libtbb2 \
        libopenblas-base \
        libopenblas-dev \
        liblapack-dev \
        libatlas-base-dev \
        #libgtk-3-dev \
        #libavcodec58 \
        libavcodec-dev \
        #libavformat58 \
        libavformat-dev \
        libavutil-dev \
        #libswscale5 \
        libswscale-dev \
        libjpeg8-dev \
        libpng-dev \
        libtiff5-dev \
        #libdc1394-22 \
        libdc1394-22-dev \
        libxine2-dev \
        libv4l-dev \
        libgstreamer1.0 \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-0 \
        libgstreamer-plugins-base1.0-dev \
        libglew-dev \
        libpostproc-dev \
        libeigen3-dev \
        libtbb-dev \
        zlib1g-dev \
        libsm6 \
        libxext6 \
        libxrender1 \
        wget \
        vim

# Install gstreamer
RUN apt-get install --no-install-recommends -y \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-doc gstreamer1.0-tools \
    gstreamer1.0-x gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 \
    gstreamer1.0-qt5 gstreamer1.0-pulseaudio

# Install OpenCV
WORKDIR /opt
RUN wget https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip -O opencv.zip --progress=bar:force:noscroll && \
    unzip -q opencv.zip && \
    mv /opt/opencv-$OPENCV_VERSION /opt/opencv && \
    rm /opt/opencv.zip && \
    wget https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERSION.zip -O opencv_contrib.zip --progress=bar:force:noscroll && \
    unzip -q opencv_contrib.zip && \
    mv /opt/opencv_contrib-$OPENCV_VERSION /opt/opencv_contrib && \
    rm opencv_contrib.zip

# Prepare build
RUN mkdir /opt/opencv/build && \
    cd /opt/opencv/build && \
    cmake \
      -D CMAKE_BUILD_TYPE=RELEASE \
      -D BUILD_PYTHON_SUPPORT=ON \
      -D BUILD_DOCS=ON \
      -D BUILD_PERF_TESTS=OFF \
      -D BUILD_TESTS=OFF \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib/modules \
      -D BUILD_opencv_python3="ON" \
      -D BUILD_opencv_python2="OFF" \
      -D PYTHON${PYTHON_VERSION%%.*}_EXECUTABLE=$(which python${PYTHON_VERSION}) \
      -D PYTHON_DEFAULT_EXECUTABLE=$(which python${PYTHON_VERSION}) \
      -D BUILD_EXAMPLES=OFF \
      -D WITH_IPP=OFF \
      -D WITH_FFMPEG=ON \
      -D WITH_GSTREAMER=ON \
      -D WITH_V4L=ON \
      -D WITH_LIBV4L=ON \
      -D WITH_TBB=ON \
      -D WITH_QT=OFF \
      -D WITH_OPENGL=ON \
      -D WITH_CUDA=ON \
      -D WITH_LAPACK=ON \
      -D WITH_CUDNN=ON \
      #-D WITH_HPX=ON \
      -D CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
      -D CMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
      # https://kezunlin.me/post/6580691f
      # https://stackoverflow.com/questions/28010399/build-opencv-with-cuda-support
      -D CUDA_ARCH_BIN="5.3 6.1 7.0 7.5" \
      -D CUDA_ARCH_PTX="" \
      -D WITH_CUBLAS=ON \
      -D WITH_NVCUVID=ON \
      -D ENABLE_FAST_MATH=ON \
      -D CUDA_FAST_MATH=ON \
      -D OPENCV_DNN_CUDA=ON \
      -D WITH_OPENMP=ON \
      -D ENABLE_PRECOMPILED_HEADERS=OFF \
      ..

# Build, Test and Install
RUN cd /opt/opencv/build && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Install torch.
RUN pip uninstall -y torch torchvision torchaudio
RUN pip install torch torchvision torchaudio

# Install python requirements
RUN pip install mediapipe nvidia-ml-py3 vidgear[asyncio] seaborn
RUN pip install pyyaml coloredlogs python-dotenv singleton_decorator
RUN pip install aiohttp requests redis
RUN pip install pafy youtube_dl yt_dlp vidgear

# Cleanup
RUN rm -rf /opt/opencv /opt/opencv_contrib

# Print version info
RUN ffmpeg -version && \
    gst-launch-1.0 --gst-version && \
    python3 -c "import cv2; print(cv2.getBuildInformation())" && \
    python3 -c "import cv2; print('cv2: ' + cv2.__version__)" && \
    python3 -c "import torch; print('torch: ' + torch.__version__)"
