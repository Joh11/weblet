all: exe

exe: clean
	sbcl --eval "(asdf:operate :build-op :weblet)"

clean:
	rm -f weblet

.PHONY: exe clean
