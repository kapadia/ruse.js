
FILES = \
	src/start.js \
	src/core.js \
	src/histogram.js \
	src/shaders.js \
	src/end.js

all:
	cat $(FILES) > ruse.js