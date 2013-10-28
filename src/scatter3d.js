
ruse.prototype.scatter3D = function(data) {
  var datum, i, index, initialVertices, max1, max2, max3, min1, min2, min3, nVertices, range1, range2, range3, vertexSize, vertices, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3;
  
  this.gl.useProgram(this.programs.ruse);
  
  if (this.state !== "scatter3D") {
    this["switch"] = 0;
    this.hasData = false;
  }
  this.state = "scatter3D";
  
  // Add perspective when working in three dimensions
  // mat4.perspective(@pMatrix, 45.0, 1.0, 0.1, 100.0)
  mat4.perspective(this.pMatrix, 45.0, this.canvas.width / this.canvas.height, 0.1, 100.0);
  this.translateBy = this.translateBy || [0.0, 0.0, -4.0];
  this.gl.uniform1f(this.uZComponent, 1.0);
  
  // Proceed to handling the real data
  vertexSize = 3;
  nVertices = data.length;
  vertices = new Float32Array(vertexSize * nVertices);
  
  _ref = Object.keys(data[0]), this.key1 = _ref[0], this.key2 = _ref[1], this.key3 = _ref[2];
  
  _ref1 = this.getExtentFromObjects(data), (_ref2 = _ref1[0], min1 = _ref2[0], min2 = _ref2[1], min3 = _ref2[2]), (_ref3 = _ref1[1], max1 = _ref3[0], max2 = _ref3[1], max3 = _ref3[2]);
  range1 = max1 - min1;
  range2 = max2 - min2;
  range3 = max3 - min3;
  for (index = _i = 0, _len = data.length; _i < _len; index = ++_i) {
    datum = data[index];
    i = vertexSize * index;
    vertices[i] = datum[this.key1];
    vertices[i + 1] = datum[this.key2];
    vertices[i + 2] = datum[this.key3];
  }
  if (!this.hasData) {
    initialVertices = new Float32Array(vertexSize * nVertices);
    for (index = _j = 0, _len1 = data.length; _j < _len1; index = ++_j) {
      datum = data[index];
      i = vertexSize * index;
      initialVertices[i] = datum[this.key1];
      initialVertices[i + 1] = datum[this.key2];
      initialVertices[i + 2] = 0;
    }
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer1);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, initialVertices, this.gl.STATIC_DRAW);
    this.extents = {
      xmin: min1,
      xmax: max1,
      ymin: min2,
      ymax: max2,
      zmin: min3,
      zmax: max3
    };
    this.hasData = true;
  }
  this.dataBuffer1.itemSize = vertexSize;
  this.dataBuffer1.numItems = nVertices;
  this.dataBuffer2.itemSize = vertexSize;
  this.dataBuffer2.numItems = nVertices;
  if (this["switch"] === 0) {
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer1);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition1, this.dataBuffer1.itemSize, this.gl.FLOAT, false, 0, 0);
    this.gl.uniform3f(this.uMinimum1, this.extents.xmin, this.extents.ymin, this.extents.zmin);
    this.gl.uniform3f(this.uMaximum1, this.extents.xmax, this.extents.ymax, this.extents.zmax);
    this.gl.uniform3f(this.uMinimum2, min1, min2, min3);
    this.gl.uniform3f(this.uMaximum2, max1, max2, max3);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer2);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, vertices, this.gl.STATIC_DRAW);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition2, this.dataBuffer2.itemSize, this.gl.FLOAT, false, 0, 0);
    this["switch"] = 1;
  } else {
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer1);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, vertices, this.gl.STATIC_DRAW);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition1, this.dataBuffer1.itemSize, this.gl.FLOAT, false, 0, 0);
    this.gl.uniform3f(this.uMinimum1, min1, min2, min3);
    this.gl.uniform3f(this.uMaximum1, max1, max2, max3);
    this.gl.uniform3f(this.uMinimum2, this.extents.xmin, this.extents.ymin, this.extents.zmin);
    this.gl.uniform3f(this.uMaximum2, this.extents.xmax, this.extents.ymax, this.extents.zmax);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer2);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition2, this.dataBuffer2.itemSize, this.gl.FLOAT, false, 0, 0);
    this["switch"] = 0;
  }
  this.extents = {
    xmin: min1,
    xmax: max1,
    ymin: min2,
    ymax: max2,
    zmin: min3,
    zmax: max3
  };
  this._setupMouseControls();
  this.removeAxes();
  this.drawMode = this.gl.POINTS;
  return this.animate();
};
