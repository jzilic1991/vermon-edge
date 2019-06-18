BIN = ~/bin/
VER = 1.1.8
USERNAME ?= $(shell bash -c 'read -r -p "Username: " uuu; echo $$uuu')
IMAGENAME ?= $(shell bash -c 'read -r -p "Image name: " iii; echo $$iii')

all: monpoly

.PHONY: monpoly doc clean clean-all depend

monpoly:
	cd src && $(MAKE) monpoly
	cp src/monpoly monpoly

doc:
	cd src && $(MAKE) doc

clean:
	cd src && $(MAKE) clean

clean-all: clean
	rm -f monpoly
	rm -f doc/*
	rm -f src/monpoly $(BIN)monpoly

depend:
	cd src && $(MAKE) depend


monpoly-$(VER).tgz:
	tar -zcf ../monpoly-$(VER).tgz ../monpoly-$(VER)

release: monpoly-$(VER).tgz


docker:
	docker build -t $(USERNAME)/$(IMAGENAME) .

docker-run:
	docker run --name monpoly -it $(USERNAME)/$(IMAGENAME)

docker-push:
	docker login
	docker push $(USERNAME)/$(IMAGENAME)
