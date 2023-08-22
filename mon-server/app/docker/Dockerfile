FROM ocaml/opam:ubuntu-20.04-ocaml-4.11

RUN sudo apt-get update \
    && sudo apt-get install -y \
    subversion \
    m4 \
    libgmp-dev \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    && sudo rm -rf /var/lib/apt/lists/*

#Allow pi wheels 
RUN mkdir -p /etc
RUN sudo chown opam /etc
USER opam
RUN echo "[global]\nextra-index-url=https://www.piwheels.org/simple" >> /etc/pip.conf

# RUN opam init -y \
RUN opam update \
    && opam switch create 4.11.1 \
    && opam install \
       ocamlfind \
       qcheck \
       zarith \
       num

# RUN useradd -ms /bin/bash monply
ENV WDIR /home/opam/monpoly
RUN mkdir -p ${WDIR}
WORKDIR ${WDIR}
ADD . ${WDIR}

# Upgrade pip and install requirements
RUN pip3 install --upgrade pip; pip3 install --no-cache-dir -r app/docker/requirements.txt;

RUN sudo chown -R opam:opam . \
    && eval `opam config env` \
    && make \
    && sudo cp ./monpoly /usr/local/bin/monpoly \
    && make clean

EXPOSE 5001
ENTRYPOINT [ "python3", "-u", "app/app/mon-server.py", "%s" ]