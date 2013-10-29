# ruse.js

`ruse.js` is a lightweight WebGL library built for plotting large datasets. It is capable of plotting millions of points at once, and smoothly transitioning between plots.

## Dependency

`ruse.js` depends only on [`gl-matrix`](https://raw.github.com/toji/gl-matrix/) for matrix transformations.

## Usage

Include `gl-matrix` and `ruse.js` into a project using the usual script tags.

    <script type="text/javascript" src="gl-matrix.js"></script>
    <script type="text/javascript" src="ruse.js"></script>
    
Set up a new plot by initializing a `ruse` object using a DOM element and specifying width and height.
    
    var el = document.querySelector("#ruse");
    var r = new ruse(el, 600, 400);

Create a plot by passing an array of key-value objects.  `ruse` determines the dimensionality based on the first key-value element in the array, and creates an appropriate plot.

    var data = [{x: 349, y: 920}, ..., {x: 192, y: 291}];
    r.plot(data);
    
To disable animation, set the animation property to `false`:

    r.animation = false;

## Development Setup

    # Get example dependencies and sample data
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

