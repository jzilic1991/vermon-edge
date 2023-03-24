FROM ocaml/opam:ubuntu-20.04-ocaml-4.11

RUN sudo apt-get update \
    && sudo apt-get install -y \
    subversion \
    m4 \
    libgmp-dev \
    && sudo rm -rf /var/lib/apt/lists/* 

# RUN opam init -y \
RUN opam update \
    && opam switch create 4.11.1 \
    && opam install \
       ocamlfind \
       qcheck \
       zarith \
       num

# RUN useradd -ms /bin/bash monply
USER opam
ENV WDIR /home/opam/monpoly
RUN mkdir -p ${WDIR}
WORKDIR ${WDIR}

ADD . ${WDIR}
RUN sudo chown -R opam:opam . \
    && eval `opam config env` \
    && make \
    && sudo cp ./monpoly /usr/local/bin/monpoly \
    && make clean 