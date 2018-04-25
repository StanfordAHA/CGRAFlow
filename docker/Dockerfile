FROM ubuntu:latest

RUN apt-get update
RUN useradd -ms /bin/bash docker && echo "docker:docker" | chpasswd

RUN apt-get install git software-properties-common wget make -y

RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test
RUN apt-get update -y
RUN apt-get install g++-4.9 -y
RUN apt-get install gcc-4.9 -y

RUN apt-get install verilator luajit build-essential clang libedit-dev libpng-dev csh libgmp3-dev git cmake zlib1g zlib1g-dev graphviz-dev python3 swig2.0 libcln-dev imagemagick python-virtualenv libxml2-dev libxslt-dev python3-dev python3-pip -y

USER docker
WORKDIR /home/docker
RUN git clone https://github.com/StanfordAHA/CGRAFlow
RUN cd CGRAFlow && ./install.sh
RUN echo 'export CGRAFLOW_PATH=$HOME/CGRAFlow' >> $HOME/.bashrc
RUN echo 'source $CGRAFLOW_PATH/setenv.sh' >> $HOME/.bashrc
# RUN cd CGRAFlow && CGRAFLOW_PATH=$PWD source setenv.sh && make core_only
