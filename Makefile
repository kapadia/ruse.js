
FILES = \
	src/core.js \
	src/histogram.js \
	src/scatter2d.js \
	src/scatter3d.js \
	src/setters.js \
	src/shaders.js \


all:
	cat src/start.js $(FILES) src/end.js > ruse.js
	node_modules/.bin/uglifyjs ruse.js -o ruse.min.js