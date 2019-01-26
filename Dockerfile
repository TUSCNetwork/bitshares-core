FROM phusion/baseimage:0.10.1
MAINTAINER The Universal Settlment Coin (TUSC) development team

ENV LANG=en_US.UTF-8
RUN \
    apt-get update -y && \
    apt-get install -y \
      g++ \
      autoconf \
      cmake \
      git \
      libbz2-dev \
      libreadline-dev \
      libboost-all-dev \
      libcurl4-openssl-dev \
      libssl-dev \
      libncurses-dev \
      doxygen \
      ca-certificates \
    && \
    apt-get update -y && \
    apt-get install -y fish && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN mkdir tusc-core
ADD . /tusc-core
WORKDIR /tusc-core

# Compile
RUN \
    ( git submodule sync --recursive || \
      find `pwd`  -type f -name .git | \
  while read f; do \
    rel="$(echo "${f#$PWD/}" | sed 's=[^/]*/=../=g')"; \
    sed -i "s=: .*/.git/=: $rel/=" "$f"; \
  done && \
      git submodule sync --recursive ) && \
    git submodule update --init --recursive && \
    cmake \
        -DCMAKE_BUILD_TYPE=Release \
        . && \
    make witness_node cli_wallet && \
    install -s programs/witness_node/witness_node programs/cli_wallet/cli_wallet /usr/local/bin && \
    #
    # Obtain version
    mkdir /etc/tusc && \
    git rev-parse --short HEAD > /etc/tusc/version && \
    cd / && \
    rm -rf /tusc-core

# Home directory $HOME
WORKDIR /
RUN witness_node --create-genesis-json=genesis.json
ADD docker/default_config.ini /witness_node_data_dir/config.ini
#  witness_node
#RUN useradd -s /bin/bash -m -d /var/lib/tusc tusc
#ENV HOME /var/lib/tusc
#RUN chown tusc:tusc -R /var/lib/tusc

# Volume
#VOLUME ["/var/lib/tusc", "/etc/tusc"]

# rpc service:
EXPOSE 8090
# p2p service:
EXPOSE 1776

# default exec/config files
#ADD docker/default_config.ini /etc/tusc/config.ini
#ADD docker/bitsharesentry.sh /usr/local/bin/bitsharesentry.sh
#RUN chmod a+x /usr/local/bin/bitsharesentry.sh

# Make Docker send SIGINT instead of SIGTERM to the daemon
STOPSIGNAL SIGINT

# default execute entry
#CMD ["/usr/local/bin/bitsharesentry.sh"]
ENTRYPOINT ["witness_node"]