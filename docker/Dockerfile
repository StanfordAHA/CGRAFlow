FROM ubuntu:trusty

# Need sudo for install.sh, ideally we wouldn't have to do this
RUN apt-get update && \
      apt-get -y install sudo
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo

# https://docs.docker.com/engine/reference/builder/#shell
# Set the SHELL to bash so we can use source
SHELL ["/bin/bash", "-c"]

RUN apt-get install git software-properties-common wget make -y
RUN git clone https://github.com/StanfordAHA/CGRAFlow $HOME/CGRAFlow
RUN cd $HOME/CGRAFlow && ./scripts/install_machine_deps.sh && ./scripts/install_locally.sh
RUN echo 'export CGRAFLOW_PATH=$HOME/CGRAFlow' >> $HOME/.bashrc
RUN echo 'source $CGRAFLOW_PATH/scripts/setenv.sh' >> $HOME/.bashrc
