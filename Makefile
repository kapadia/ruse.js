
FILES = \
	src/start.js \
	src/core.js \
	src/shaders.js \
	src/end.js

all:
	cat $(FILES) > ruse.js