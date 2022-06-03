.PHONY: update_binaries build

all: update_binaries build

update_binaries:
	cd binaries && make

build:
	./build.sh