# @ author: Kangyao Huang
# @   date: Mar.31.2023

# If you want to use a different version of CUDA, view the available
# images here: https://hub.docker.com/r/nvidia/cuda
# Note:
#   - Jax currently supports CUDA versions up to 11.3.
#   - Tensorflow required CUDA versions after 11.2.
ARG cuda_docker_tag="11.2.2-cudnn8-devel-ubuntu20.04"
FROM nvidia/cuda:${cuda_docker_tag}

RUN apt-get update
# tzdata is required below. To avoid hanging, install it first.
RUN DEBIAN_FRONTEND="noninteractive" apt-get install tzdata -y
RUN apt-get install git wget libgl1-mesa-glx -y

# Install python3.8.
RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:deadsnakes/ppa -y
RUN apt-get install python3.8 -y

# Make python3.8 the default python.
RUN rm /usr/bin/python3
RUN ln -s /usr/bin/python3.8 /usr/bin/python3
RUN ln -s /usr/bin/python3.8 /usr/bin/python
RUN apt-get install python3-distutils -y

# Install pip.
RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python get-pip.py
RUN rm get-pip.py

# Create Mujoco subdir.
RUN mkdir /root/.mujoco
COPY mjkey.txt /root/.mujoco/mjkey.txt

# Prerequisites
RUN apt-get install \
  libosmesa6-dev \
  libgl1-mesa-glx \
  libglfw3 \
  libglew-dev \
  patchelf \
  gcc \
  python3.8-dev \
  unzip -y \
  libxrandr2 \
  libxinerama1 \
  libxcursor1 \
  vim \
  openssh-server

# SSH config
RUN echo "root:123123" | chpasswd
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
RUN echo 'X11Forwarding yes' >> /etc/ssh/sshd_config
RUN echo 'X11Displayoffset 10' >> /etc/ssh/sshd_config
RUN echo 'X11UseLocalhost no' >> /etc/ssh/sshd_config
RUN service ssh restart

# set SSH auto-on
RUN touch /root/start_ssh.sh
RUN echo '#!/bin/bash \n\
  LOGTIME=$(date "+%Y-%m-%d %H:%M:%S") \n\
  echo "[$LOGTIME] startup run..." >>/root/start_ssh.log \n\
  service ssh start >>/root/start_ssh.log' >> /root/start_ssh.sh
RUN chmod +x /root/start_ssh.sh
RUN echo '# startup run \n\
  if [ -f /root/start_ssh.sh ]; then \n\
      /root/start_ssh.sh \n\
  fi' >> /root/.bashrc

# Download and install mujoco.
RUN wget https://www.roboti.us/download/mujoco200_linux.zip
RUN unzip mujoco200_linux.zip
RUN rm mujoco200_linux.zip
RUN mv mujoco200_linux /root/.mujoco/mujoco200
RUN wget -P /root/.mujoco/mujoco200/bin/ https://roboti.us/file/mjkey.txt

# Add LD_LIBRARY_PATH environment variable.
ENV LD_LIBRARY_PATH "/root/.mujoco/mujoco200/bin:${LD_LIBRARY_PATH}"
RUN echo 'export LD_LIBRARY_PATH=/root/.mujoco/mujoco200/bin:${LD_LIBRARY_PATH}' >> /etc/bash.bashrc

# Finally, install mujoco_py.
RUN pip install mujoco_py==2.0.2.8
