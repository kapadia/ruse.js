# Clean up directories
rm examples/lib/*
rm examples/data/*

mkdir -vp examples/lib
mkdir -vp examples/data

curl -k "https://raw.github.com/astrojs/fitsjs/rewrite/lib/fits.js" -o 'examples/lib/fits.js'
curl -k "https://raw.github.com/toji/gl-matrix/master/dist/gl-matrix.js" -o 'examples/lib/gl-matrix.js'
curl -k "http://astrojs.s3.amazonaws.com/sample/plates-dr9.fits" -o 'examples/data/plates-dr9.fits'