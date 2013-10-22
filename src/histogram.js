
ruse.prototype.getHistogram = function(arr, min, max, bins) {
  var dx, h, i, index, range, value;
  range = max - min;
  h = new Uint32Array(bins);
  dx = range / bins;
  i = arr.length;
  while (i--) {
    value = arr[i];
    index = ~~((value - min) / dx);
    h[index] += 1;
  }
  h.dx = dx;
  return h;
};

ruse.prototype.histogram = function(data) {
  var clipspaceBinWidth, clipspaceLower, clipspaceSize, clipspaceUpper, dataMax, dataMin, datum, h, histMax, histMin, i, index, initialVertices, key, margin, nVertices, value, vertexSize, vertices, width, x, y, y0, _i, _j, _len, _len1, _ref, _ref1;
  this.gl.useProgram(this.programs.ruse);
  if (this.state !== "histogram") {
    this["switch"] = 0;
    this.hasData = false;
  }
  this.state = "histogram";
  this.gl.uniform1f(this.uZComponent, 0.0);
  mat4.identity(this.pMatrix);
  mat4.identity(this.mvMatrix);
  mat4.identity(this.rotationMatrix);
  this.translateBy = [0.0, 0.0, 0.0];
  margin = this.getMargin();
  datum = data[0];
  if (this.isObject(datum)) {
    key = Object.keys(datum)[0];
    this.key1 = key;
    this.key2 = "";
    data = data.map(function(d) {
      return d[key];
    });
  }
  _ref = this.getExtent(data), dataMin = _ref[0], dataMax = _ref[1];
  if (!this.bins) {
    width = this.width - this.getMargin() * this.width;
    this.bins = Math.floor(width / this.targetBinWidth);
  }
  h = this.getHistogram(data, dataMin, dataMax, this.bins);
  _ref1 = this.getExtent(h), histMin = _ref1[0], histMax = _ref1[1];
  clipspaceSize = 2.0;
  clipspaceBinWidth = clipspaceSize / this.bins;
  clipspaceLower = -1.0;
  clipspaceUpper = 1.0;
  vertexSize = 2;
  nVertices = 6 * this.bins;
  vertices = new Float32Array(vertexSize * nVertices);
  x = -1.0;
  y = y0 = -1.0;
  for (index = _i = 0, _len = h.length; _i < _len; index = ++_i) {
    value = h[index];
    i = 12 * index;
    vertices[i + 0] = x;
    vertices[i + 1] = y0;
    vertices[i + 2] = x;
    vertices[i + 3] = (clipspaceUpper - clipspaceLower) * value / histMax + clipspaceLower;
    vertices[i + 4] = x + clipspaceBinWidth;
    vertices[i + 5] = y0;
    vertices[i + 6] = vertices[i + 4];
    vertices[i + 7] = vertices[i + 5];
    vertices[i + 8] = vertices[i + 4];
    vertices[i + 9] = vertices[i + 3];
    vertices[i + 10] = vertices[i + 2];
    vertices[i + 11] = vertices[i + 3];
    x += clipspaceBinWidth;
  }
  if (!this.hasData) {
    initialVertices = new Float32Array(vertexSize * nVertices);
    for (i = _j = 0, _len1 = vertices.length; _j < _len1; i = _j += 2) {
      datum = vertices[i];
      initialVertices[i] = datum;
      initialVertices[i + 1] = -1.0;
    }
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer1);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, initialVertices, this.gl.STATIC_DRAW);
    this.extents = {
      xmin: dataMin,
      xmax: dataMax,
      ymin: histMin,
      ymax: histMax
    };
    this.hasData = true;
  }
  this.dataBuffer1.itemSize = vertexSize;
  this.dataBuffer1.numItems = nVertices;
  this.dataBuffer2.itemSize = vertexSize;
  this.dataBuffer2.numItems = nVertices;
  this.gl.uniform3f(this.uMinimum1, -1, -1, 0);
  this.gl.uniform3f(this.uMaximum1, 1, 1, 1);
  this.gl.uniform3f(this.uMinimum2, -1, -1, 0);
  this.gl.uniform3f(this.uMaximum2, 1, 1, 1);
  if (this["switch"] === 0) {
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer1);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition1, this.dataBuffer1.itemSize, this.gl.FLOAT, false, 0, 0);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer2);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, vertices, this.gl.STATIC_DRAW);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition2, this.dataBuffer2.itemSize, this.gl.FLOAT, false, 0, 0);
    this["switch"] = 1;
  } else {
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer1);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, vertices, this.gl.STATIC_DRAW);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition1, this.dataBuffer1.itemSize, this.gl.FLOAT, false, 0, 0);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer2);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition2, this.dataBuffer2.itemSize, this.gl.FLOAT, false, 0, 0);
    this["switch"] = 0;
  }
  this.extents = {
    xmin: dataMin,
    xmax: dataMax,
    ymin: histMin,
    ymax: histMax
  };
  this.drawAxes();
  this.drawMode = this.gl.TRIANGLES;
  this.axesCanvas.onmousemove = null;
  return this.animate();
};
