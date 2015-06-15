// Data should be a Float32Array containing x/y values serialized as x0, y0, x1, y1, etc.
ruse.prototype.scatter2D = function(data) {
  var datum, i, index, initialVertices, margin, max1, max2, min1, min2, nVertices, range1, range2, vertexSize, _i, _j, _len, _len1, _ref, _ref1, _ref2, _ref3;

  this.gl.useProgram(this.programs.ruse);
  if (this.state !== "scatter2D") {
    this["switch"] = 0;
    this.hasData = false;
  }
  
  this.state = "scatter2D";
  this.gl.uniform1f(this.uZComponent, 0.0);
  
  mat4.identity(this.pMatrix);
  mat4.identity(this.mvMatrix);
  mat4.identity(this.rotationMatrix);
  
  this.translateBy = [0.0, 0.0, 0.0];
  margin = this.getMargin();
  
  vertexSize = 2;
  nVertices = data.length / 2;
  
  _ref = Object.keys(data[0]), this.key1 = _ref[0], this.key2 = _ref[1];
  _ref1 = this.getExtentFromObjects(data), (_ref2 = _ref1[0], min1 = _ref2[0], min2 = _ref2[1]), (_ref3 = _ref1[1], max1 = _ref3[0], max2 = _ref3[1]);
  
  range1 = max1 - min1;
  range2 = max2 - min2;
  
  if (!this.hasData) {
    
    // Another set of x-y values are stored here, used for transition from one
    // dataset to another.
    initialVertices = new Float32Array(data);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer1);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, initialVertices, this.gl.STATIC_DRAW);
    this.extents = {
      xmin: min1,
      xmax: max1,
      ymin: min2,
      ymax: max2
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
    this.gl.uniform3f(this.uMinimum1, this.extents.xmin, this.extents.ymin, 0);
    this.gl.uniform3f(this.uMaximum1, this.extents.xmax, this.extents.ymax, 1);
    this.gl.uniform3f(this.uMinimum2, min1, min2, 0);
    this.gl.uniform3f(this.uMaximum2, max1, max2, 1);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer2);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, data, this.gl.STATIC_DRAW);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition2, this.dataBuffer2.itemSize, this.gl.FLOAT, false, 0, 0);
    this["switch"] = 1;
  } else {
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer1);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, data, this.gl.STATIC_DRAW);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition1, this.dataBuffer1.itemSize, this.gl.FLOAT, false, 0, 0);
    this.gl.uniform3f(this.uMinimum1, min1, min2, 0);
    this.gl.uniform3f(this.uMaximum1, max1, max2, 1);
    this.gl.uniform3f(this.uMinimum2, this.extents.xmin, this.extents.ymin, 0);
    this.gl.uniform3f(this.uMaximum2, this.extents.xmax, this.extents.ymax, 1);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.dataBuffer2);
    this.gl.vertexAttribPointer(this.programs.ruse.aVertexPosition2, this.dataBuffer2.itemSize, this.gl.FLOAT, false, 0, 0);
    this["switch"] = 0;
  }
  
  this.extents = {
    xmin: min1,
    xmax: max1,
    ymin: min2,
    ymax: max2
  };
  
  this.drawAxes();
  this.drawMode = this.gl.POINTS;
  
  // Disable mouse events
  this.axesCanvas.onmousemove = null;
  this.axesCanvas.onwheel = null;
  this.axesCanvas.onmousewheel = null;
  
  this.redraw();
};
