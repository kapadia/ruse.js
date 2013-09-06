# ruse.js

`ruse.js` is a WebGL plotting library.  It is capable of plotting millions of points using a modern browser.

## Dependency

`ruse.js` depends only on [`gl-matrix`](https://raw.github.com/toji/gl-matrix/) for matrix transformations.

## Usage

Include 'gl-matrix' and 'ruse' into a project using the usual script tags.

    <script type="text/javascript" src="gl-matrix.js"></script>
    <script type="text/javascript" src="ruse.js"></script>
    
Set up a new plot by initializing a `ruse` object with a DOM element and specifying the width and height.
    
    var el = document.querySelector("#ruse");
    var ruse = new astro.Ruse(el, 600, 400);

Create a plot by passing an array of key-value objects.  `ruse` determines the dimensionality based on the first key-value element in the array, and creates an appropriate plot.

    var data = [{x: 349, y: 920}, ..., {x: 192, y: 291}];
    ruse.plot(data);

## Development Setup

    # Get dependencies and sample data for examples
    ./setup.sh
    
    # Install development dependencies
    npm install
    
    # Start a local server
    npm start

## Data

Ruse accepts data in the following form:

    var arr = [{x: 123, y: 456}, ..., {x: 987, y: 654}]

## API

  plot(data)

