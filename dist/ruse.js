// Generated by CoffeeScript 1.6.3
(function() {
  var Ruse, Shaders,
    __slice = [].slice;

  Ruse = (function() {
    Ruse.prototype._loadShader = function(gl, source, type) {
      var compiled, lastError, shader;
      shader = gl.createShader(type);
      gl.shaderSource(shader, source);
      gl.compileShader(shader);
      compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
      if (!compiled) {
        lastError = gl.getShaderInfoLog(shader);
        throw "Error compiling shader " + shader + ": " + lastError;
        gl.deleteShader(shader);
        return null;
      }
      return shader;
    };

    Ruse.prototype._createProgram = function(gl, vertexShader, fragmentShader) {
      var linked, program;
      vertexShader = this._loadShader(gl, vertexShader, gl.VERTEX_SHADER);
      fragmentShader = this._loadShader(gl, fragmentShader, gl.FRAGMENT_SHADER);
      program = gl.createProgram();
      gl.attachShader(program, vertexShader);
      gl.attachShader(program, fragmentShader);
      gl.linkProgram(program);
      linked = gl.getProgramParameter(program, gl.LINK_STATUS);
      if (!linked) {
        throw "Error in program linking: " + (gl.getProgramInfoLog(program));
        gl.deleteProgram(program);
        return null;
      }
      gl.useProgram(program);
      program.points1Attribute = gl.getAttribLocation(program, "aPoints1");
      gl.enableVertexAttribArray(program.points1Attribute);
      program.points2Attribute = gl.getAttribLocation(program, "aPoints2");
      gl.enableVertexAttribArray(program.points2Attribute);
      program.uPMatrix = gl.getUniformLocation(program, "uPMatrix");
      program.uMVMatrix = gl.getUniformLocation(program, "uMVMatrix");
      return program;
    };

    Ruse.prototype._createProgram3D = function(gl, vertexShader, fragmentShader) {
      var linked, program;
      vertexShader = this._loadShader(gl, vertexShader, gl.VERTEX_SHADER);
      fragmentShader = this._loadShader(gl, fragmentShader, gl.FRAGMENT_SHADER);
      program = gl.createProgram();
      gl.attachShader(program, vertexShader);
      gl.attachShader(program, fragmentShader);
      gl.linkProgram(program);
      linked = gl.getProgramParameter(program, gl.LINK_STATUS);
      if (!linked) {
        throw "Error in program linking: " + (gl.getProgramInfoLog(program));
        gl.deleteProgram(program);
        return null;
      }
      gl.useProgram(program);
      program.vertexPositionAttribute = gl.getAttribLocation(program, "aVertexPosition");
      gl.enableVertexAttribArray(program.vertexPositionAttribute);
      program.uPMatrix = gl.getUniformLocation(program, "uPMatrix");
      program.uMVMatrix = gl.getUniformLocation(program, "uMVMatrix");
      return program;
    };

    Ruse.prototype._setMatrices = function(program) {
      this.gl.useProgram(program);
      this.gl.uniformMatrix4fv(program.uPMatrix, false, this.pMatrix);
      return this.gl.uniformMatrix4fv(program.uMVMatrix, false, this.mvMatrix);
    };

    Ruse.prototype._toRadians = function(deg) {
      return deg * 0.017453292519943295;
    };

    Ruse.prototype._setupMouseControls = function() {
      var _this = this;
      this.drag = false;
      this.xOldOffset = null;
      this.yOldOffset = null;
      this.xOffset = 0;
      this.yOffset = 0;
      this.axesCanvas.onmousedown = function(e) {
        _this.drag = true;
        _this.xOldOffset = e.clientX;
        return _this.yOldOffset = e.clientY;
      };
      this.axesCanvas.onmouseup = function(e) {
        return _this.drag = false;
      };
      this.axesCanvas.onmousemove = function(e) {
        var deltaX, deltaY, rotationMatrix, x, y;
        if (!_this.drag) {
          return;
        }
        x = e.clientX;
        y = e.clientY;
        deltaX = x - _this.xOldOffset;
        deltaY = y - _this.yOldOffset;
        rotationMatrix = mat4.create();
        mat4.identity(rotationMatrix);
        mat4.rotateY(rotationMatrix, rotationMatrix, _this._toRadians(deltaX / 4));
        mat4.rotateX(rotationMatrix, rotationMatrix, _this._toRadians(deltaY / 4));
        mat4.multiply(_this.rotationMatrix, rotationMatrix, _this.rotationMatrix);
        _this.xOldOffset = x;
        _this.yOldOffset = y;
        return _this.draw3d();
      };
      this.axesCanvas.onmouseout = function(e) {
        return _this.drag = false;
      };
      return this.axesCanvas.onmouseover = function(e) {
        return _this.drag = false;
      };
    };

    function Ruse(arg, width, height) {
      var s, shaders;
      this.margin = 0.02;
      this.fontSize = 10;
      this.tickFontSize = 9;
      this.fontFamily = "Helvetica";
      this.axisPadding = 4;
      this.xTicks = 6;
      this.yTicks = 6;
      this.xTickSize = 4;
      this.yTickSize = 4;
      this.tickDecimals = 3;
      this.targetBinWidth = 1;
      this.bins = null;
      this.drawMode = null;
      this.extents = null;
      this.hasData = false;
      s = arg.constructor.toString();
      if (s.indexOf('WebGLRenderingContext') > -1 || s.indexOf('rawgl') > -1) {
        this.gl = arg;
        this.canvas = arg.canvas;
        this.width = this.canvas.width;
        this.height = this.canvas.height;
        this.canvas.style.position = 'absolute';
      } else {
        this.width = width;
        this.height = height;
        this.canvas = document.createElement('canvas');
        this.canvas.setAttribute('width', this.width);
        this.canvas.setAttribute('height', this.height);
        this.canvas.setAttribute('class', 'ruse');
        this.canvas.style.position = 'absolute';
        this.gl = this.canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
        if (!this.gl) {
          return null;
        }
        arg.appendChild(this.canvas);
      }
      this.axesCanvas = document.createElement('canvas');
      this.axesCanvas.setAttribute('width', this.width);
      this.axesCanvas.setAttribute('height', this.height);
      this.axesCanvas.setAttribute('class', 'ruse axes');
      this.axesCanvas.style.position = 'absolute';
      this.gl.canvas.parentElement.appendChild(this.axesCanvas);
      shaders = this.constructor.Shaders;
      this.programs = {};
      this.programs["ruse"] = this._createProgram(this.gl, shaders.vertex, shaders.fragment);
      this.programs["three"] = this._createProgram3D(this.gl, shaders.vertex3D, shaders.fragment);
      this.gl.useProgram(this.programs.ruse);
      this.uTime = this.gl.getUniformLocation(this.programs.ruse, "uTime");
      this.uSwitch = this.gl.getUniformLocation(this.programs.ruse, "uSwitch");
      this.uMargin = this.gl.getUniformLocation(this.programs.ruse, "uMargin");
      this.uMinimum1 = this.gl.getUniformLocation(this.programs.ruse, "uMinimum1");
      this.uMaximum1 = this.gl.getUniformLocation(this.programs.ruse, "uMaximum1");
      this.uMinimum2 = this.gl.getUniformLocation(this.programs.ruse, "uMinimum2");
      this.uMaximum2 = this.gl.getUniformLocation(this.programs.ruse, "uMaximum2");
      this.uMinimum = this.gl.getUniformLocation(this.programs.three, "uMinimum");
      this.uMaximum = this.gl.getUniformLocation(this.programs.three, "uMaximum");
      this["switch"] = 0;
      this.gl.uniform1f(this.uTime, 0);
      this.gl.uniform1f(this.uSwitch, this["switch"]);
      this.gl.uniform1f(this.uMargin, this.getMargin());
      this.pMatrix = mat4.create();
      this.mvMatrix = mat4.create();
      this.rotationMatrix = mat4.create();
      mat4.identity(this.pMatrix);
      mat4.identity(this.rotationMatrix);
      mat4.identity(this.mvMatrix);
      this._setMatrices(this.programs.ruse);
      this.gl.viewport(0, 0, this.width, this.height);
      this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);
      this.gl.enable(this.gl.DEPTH_TEST);
      this.state1Buffer = this.gl.createBuffer();
      this.state2Buffer = this.gl.createBuffer();
      this.finalBuffer = this.state2Buffer;
      this.threeBuffer = this.gl.createBuffer();
    }

    Ruse.prototype.draw = function() {
      this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);
      this._setMatrices(this.programs.ruse);
      return this.gl.drawArrays(this.drawMode, 0, this.finalBuffer.numItems);
    };

    Ruse.prototype.drawAxes = function() {
      var context, i, index, key1width, key2width, lineWidth, lineWidthX, lineWidthY, margin, textWidth, value, vertices, x, x1, x2, xTick, xTickValues, xTicks, xp, y, y1, y2, yTick, yTickValues, yTicks, yp, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3;
      this.axesCanvas.width = this.axesCanvas.width;
      context = this.axesCanvas.getContext('2d');
      context.imageSmoothingEnabled = false;
      context.lineWidth = 1;
      context.font = "" + this.fontSize + "px " + this.fontFamily;
      context.translate(this.xOffset, this.yOffset);
      lineWidth = context.lineWidth;
      lineWidthX = lineWidth * 2 / this.width;
      lineWidthY = lineWidth * 2 / this.height;
      margin = this.getMargin();
      vertices = new Float32Array([-1.0 + margin - lineWidthX, 1.0, -1.0 + margin - lineWidthX, -1.0, -1.0, -1.0 + margin - lineWidthY, 1.0, -1.0 + margin - lineWidthY]);
      for (i = _i = 0, _len = vertices.length; _i < _len; i = _i += 2) {
        value = vertices[i];
        xp = vertices[i];
        yp = vertices[i + 1];
        _ref = this.xpyp2xy(xp, yp), x = _ref[0], y = _ref[1];
        vertices[i] = x;
        vertices[i + 1] = y;
      }
      context.beginPath();
      context.moveTo(vertices[0], vertices[1]);
      context.lineTo(vertices[2], vertices[3]);
      context.closePath();
      context.stroke();
      context.beginPath();
      context.moveTo(vertices[4], vertices[5]);
      context.lineTo(vertices[6], vertices[7]);
      context.closePath();
      context.stroke();
      _ref1 = this.xpyp2xy(-1.0 + margin, -1.0 + margin), x1 = _ref1[0], y1 = _ref1[1];
      _ref2 = this.xpyp2xy(1.0 - margin, 1.0 - margin), x2 = _ref2[0], y2 = _ref2[1];
      xTicks = this.linspace(x1, x2, this.xTicks + 1).subarray(1);
      yTicks = this.linspace(y1, y2, this.yTicks + 1).subarray(1);
      if (this.extents != null) {
        context.font = "" + this.tickFontSize + "px " + this.fontFamily;
        xTickValues = this.linspace(this.extents.xmin, this.extents.xmax, this.xTicks + 1).subarray(1);
        yTickValues = this.linspace(this.extents.ymin, this.extents.ymax, this.yTicks + 1).subarray(1);
      }
      for (index = _j = 0, _len1 = xTicks.length; _j < _len1; index = ++_j) {
        xTick = xTicks[index];
        context.beginPath();
        context.moveTo(xTick, y1);
        context.lineTo(xTick, y1 - this.xTickSize);
        context.stroke();
        if (xTickValues != null) {
          value = xTickValues[index].toFixed(this.tickDecimals);
          textWidth = context.measureText(value).width;
          context.fillText("" + value, xTick - textWidth + 1, y1 + this.fontSize + 2);
        }
      }
      for (index = _k = 0, _len2 = yTicks.length; _k < _len2; index = ++_k) {
        yTick = yTicks[index];
        context.beginPath();
        context.moveTo(x1 - 1, yTick);
        context.lineTo(x1 - 1 + this.yTickSize, yTick);
        context.stroke();
        if (yTickValues != null) {
          value = yTickValues[index].toFixed(this.tickDecimals);
          textWidth = context.measureText(value).width;
          context.save();
          context.rotate(-Math.PI / 2);
          context.fillText("" + value, -1 * (yTick + textWidth - 1), x1 - this.fontSize);
          context.restore();
        }
      }
      context.font = "" + this.fontSize + "px " + this.fontFamily;
      key1width = context.measureText(this.key1).width;
      key2width = context.measureText(this.key2).width;
      _ref3 = this.xpyp2xy(1.0 - margin, -1.0 + margin), x = _ref3[0], y = _ref3[1];
      x -= key1width;
      y += 2 * this.fontSize + 8;
      context.fillText("" + this.key1, x, y);
      context.save();
      context.rotate(-Math.PI / 2);
      x = -1 * (margin * this.height / 2 + key2width);
      y = margin * this.width / 2 - 2 * this.fontSize - 8;
      context.fillText("" + this.key2, x, y);
      return context.restore();
    };

    Ruse.prototype.getMargin = function() {
      return this.margin + (2 * this.fontSize + this.axisPadding) * 2 / this.height;
    };

    Ruse.prototype.setInitialBuffer = function(buffer, attribute, vertexSize, nVertices, vertices) {
      var index, initialVertices, value, _i, _len;
      initialVertices = new Float32Array(vertexSize * nVertices);
      for (index = _i = 0, _len = vertices.length; _i < _len; index = _i += 2) {
        value = vertices[index];
        initialVertices[index] = vertices[index];
        initialVertices[index + 1] = -1.0 + this.getMargin();
      }
      this.gl.bindBuffer(this.gl.ARRAY_BUFFER, buffer);
      this.gl.bufferData(this.gl.ARRAY_BUFFER, initialVertices, this.gl.STATIC_DRAW);
      buffer.itemSize = vertexSize;
      buffer.numItems = nVertices;
      return this.gl.vertexAttribPointer(attribute, buffer.itemSize, this.gl.FLOAT, false, 0, 0);
    };

    Ruse.prototype.delegateBuffers = function() {
      var finalAttribute, finalBuffer, initialAttribute, initialBuffer;
      if (this["switch"] === 0) {
        initialBuffer = this.state1Buffer;
        finalBuffer = this.state2Buffer;
        initialAttribute = this.programs.ruse.points2Attribute;
        finalAttribute = this.programs.ruse.points1Attribute;
      } else {
        initialBuffer = this.state2Buffer;
        finalBuffer = this.state1Buffer;
        initialAttribute = this.programs.ruse.points1Attribute;
        finalAttribute = this.programs.ruse.points2Attribute;
      }
      return [initialBuffer, initialAttribute, finalBuffer, finalAttribute];
    };

    Ruse.prototype.x2xp = function(x) {
      return 2 / this.width * x;
    };

    Ruse.prototype.y2yp = function(y) {
      return -2 / this.height * y;
    };

    Ruse.prototype.xp2x = function(xp) {
      return xp * this.width / 2;
    };

    Ruse.prototype.yp2y = function(yp) {
      return yp * this.height / 2;
    };

    Ruse.prototype.xy2xpyp = function(x, y) {
      var xp, yp;
      xp = 2 / this.width * x - 1;
      yp = -2 / this.height * y + 1;
      return [xp, yp];
    };

    Ruse.prototype.xpyp2xy = function(xp, yp) {
      var x, y;
      x = this.width / 2 * (xp + 1);
      y = -this.height / 2 * (yp - 1);
      return [x, y];
    };

    Ruse.prototype.isArray = function(obj) {
      var type;
      type = Object.prototype.toString.call(obj);
      if (type.indexOf('Array') > -1) {
        return true;
      } else {
        return false;
      }
    };

    Ruse.prototype.isObject = function(obj) {
      var type;
      type = Object.prototype.toString.call(obj);
      if (type.indexOf('Object') > -1) {
        return true;
      } else {
        return false;
      }
    };

    Ruse.prototype.linspace = function(start, stop, num) {
      var range, step, steps;
      range = stop - start;
      step = range / (num - 1);
      steps = new Float32Array(num);
      while (num--) {
        steps[num] = start + num * step;
      }
      return steps;
    };

    Ruse.prototype.getExtent = function(arr) {
      var index, max, min, value;
      index = arr.length;
      while (index--) {
        value = arr[index];
        if (isNaN(value)) {
          continue;
        }
        min = max = value;
        break;
      }
      while (index--) {
        value = arr[index];
        if (isNaN(value)) {
          continue;
        }
        if (value < min) {
          min = value;
        }
        if (value > max) {
          max = value;
        }
      }
      return [min, max];
    };

    Ruse.prototype.plot = function() {
      var arg, args, datum, dimensions, keys;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (args.length === 1) {
        arg = args[0];
        if (this.isArray(arg)) {
          datum = arg[0];
          if (this.isObject(datum)) {
            keys = Object.keys(datum);
            dimensions = keys.length;
            switch (dimensions) {
              case 1:
                this.histogram(arg);
                return;
              case 2:
                this.scatter2D(arg);
                return;
              case 3:
                this.scatter3D(arg);
                return;
            }
          } else {
            this.histogram(arg);
            return;
          }
        }
      }
      switch (args.length) {
        case 2:
          this.scatter2D.apply(this, args);
          return;
        case 3:
          this.scatter3D.apply(this, args);
          return;
      }
      throw "Input data not recognized by Ruse.";
    };

    Ruse.prototype.step = function(i) {
      this.gl.uniform1f(this.uTime, i / 45);
      return this.draw();
    };

    Ruse.prototype.reset = function() {
      this["switch"] = this["switch"] === 0 ? 1 : 0;
      this.gl.uniform1f(this.uTime, 0);
      this.gl.uniform1f(this.uSwitch, this["switch"]);
      return this.draw();
    };

    Ruse.prototype.animate = function() {
      var i, intervalId,
        _this = this;
      this.gl.useProgram(this.programs.ruse);
      i = 0;
      return intervalId = setInterval(function() {
        i += 1;
        _this.gl.uniform1f(_this.uTime, i / 45);
        _this.draw();
        if (i === 45) {
          clearInterval(intervalId);
          _this["switch"] = _this["switch"] === 0 ? 1 : 0;
          _this.gl.uniform1f(_this.uTime, 0);
          _this.gl.uniform1f(_this.uSwitch, _this["switch"]);
          return _this.draw();
        }
      }, 1000 / 60);
    };

    return Ruse;

  })();

  if (this.astro == null) {
    this.astro = {};
  }

  this.astro.Ruse = Ruse;

  this.astro.Ruse.version = '0.1.0';

  Ruse = this.astro.Ruse;

  Ruse.prototype.setFontSize = function(value) {
    this.fontSize = value;
    return this.drawAxes();
  };

  Ruse.prototype.getHistogram = function(arr, min, max, bins) {
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

  Ruse.prototype.histogram = function(data) {
    var clipspaceBinWidth, clipspaceLower, clipspaceSize, clipspaceUpper, countMax, countMin, datum, finalAttribute, finalBuffer, h, histMax, histMin, i, index, initialAttribute, initialBuffer, key, margin, max, min, nVertices, value, vertexSize, vertices, width, x, y, y0, _i, _len, _ref, _ref1, _ref2, _ref3;
    datum = data[0];
    if (this.isObject(datum)) {
      key = Object.keys(datum)[0];
      this.key1 = key;
      this.key2 = "";
      data = data.map(function(d) {
        return d[key];
      });
    }
    _ref = this.getExtent(data), min = _ref[0], max = _ref[1];
    if (!this.bins) {
      width = this.width - this.getMargin() * this.width;
      this.bins = Math.floor(width / this.targetBinWidth);
    }
    h = this.getHistogram(data, min, max, this.bins);
    _ref1 = this.getExtent(h), countMin = _ref1[0], countMax = _ref1[1];
    this.extents = {
      xmin: min,
      xmax: max,
      ymin: countMin,
      ymax: countMax
    };
    margin = this.getMargin();
    clipspaceSize = 2.0 - 2 * margin;
    clipspaceLower = -1.0 + margin;
    clipspaceUpper = 1.0 - margin;
    clipspaceBinWidth = clipspaceSize / this.bins;
    _ref2 = this.getExtent(h), histMin = _ref2[0], histMax = _ref2[1];
    vertexSize = 2;
    nVertices = 6 * this.bins;
    vertices = new Float32Array(vertexSize * nVertices);
    x = -1.0 + margin;
    y = y0 = -1.0 + margin;
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
    this.gl.useProgram(this.programs.ruse);
    _ref3 = this.delegateBuffers(), initialBuffer = _ref3[0], initialAttribute = _ref3[1], finalBuffer = _ref3[2], finalAttribute = _ref3[3];
    if (!this.hasData) {
      this.setInitialBuffer(initialBuffer, initialAttribute, vertexSize, nVertices, vertices);
    }
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, finalBuffer);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, vertices, this.gl.STATIC_DRAW);
    finalBuffer.itemSize = vertexSize;
    finalBuffer.numItems = nVertices;
    this.gl.vertexAttribPointer(finalAttribute, finalBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    this.hasData = true;
    this.drawMode = this.gl.TRIANGLES;
    this.drawAxes();
    return this.animate();
  };

  Ruse = this.astro.Ruse;

  Ruse.prototype.scatter2D = function(data) {
    var datum, finalAttribute, finalBuffer, i, index, initialAttribute, initialBuffer, margin, max1, max2, min1, min2, nVertices, range1, range2, uMaximum, uMinimum, val1, val2, vertexSize, vertices, _i, _len, _ref, _ref1;
    this.gl.useProgram(this.programs.ruse);
    mat4.identity(this.pMatrix);
    mat4.identity(this.mvMatrix);
    margin = this.getMargin();
    vertexSize = 2;
    nVertices = data.length;
    vertices = new Float32Array(vertexSize * nVertices);
    _ref = Object.keys(data[0]), this.key1 = _ref[0], this.key2 = _ref[1];
    i = nVertices;
    min1 = max1 = data[i - 1][this.key1];
    min2 = max2 = data[i - 1][this.key2];
    while (i--) {
      val1 = data[i][this.key1];
      val2 = data[i][this.key2];
      if (val1 < min1) {
        min1 = val1;
      }
      if (val1 > max1) {
        max1 = val1;
      }
      if (val2 < min2) {
        min2 = val2;
      }
      if (val2 > max2) {
        max2 = val2;
      }
    }
    this.extents = {
      xmin: min1,
      xmax: max1,
      ymin: min2,
      ymax: max2
    };
    if (this["switch"] === 0) {
      uMinimum = this.uMinimum1;
      uMaximum = this.uMaximum1;
    } else {
      uMinimum = this.uMinimum2;
      uMaximum = this.uMaximum2;
    }
    this.gl.uniform3f(uMinimum, min1, min2, 0);
    this.gl.uniform3f(uMaximum, max1, max2, 1);
    range1 = max1 - min1;
    range2 = max2 - min2;
    for (index = _i = 0, _len = data.length; _i < _len; index = ++_i) {
      datum = data[index];
      i = vertexSize * index;
      vertices[i] = datum[this.key1];
      vertices[i + 1] = datum[this.key2];
    }
    _ref1 = this.delegateBuffers(), initialBuffer = _ref1[0], initialAttribute = _ref1[1], finalBuffer = _ref1[2], finalAttribute = _ref1[3];
    this.finalBuffer = finalBuffer;
    if (!this.hasData) {
      this.setInitialBuffer(initialBuffer, initialAttribute, vertexSize, nVertices, vertices);
      this.gl.uniform3f(this.uMinimum1, min1, min2, 0);
      this.gl.uniform3f(this.uMaximum1, max1, max2, 1);
      this.gl.uniform3f(this.uMinimum2, min1, min2, 0);
      this.gl.uniform3f(this.uMaximum2, max1, max2, 1);
    }
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.finalBuffer);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, vertices, this.gl.STATIC_DRAW);
    this.finalBuffer.itemSize = vertexSize;
    this.finalBuffer.numItems = nVertices;
    this.gl.vertexAttribPointer(finalAttribute, this.finalBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    this.hasData = true;
    this.drawMode = this.gl.POINTS;
    this.drawAxes();
    return this.animate();
  };

  Ruse = this.astro.Ruse;

  Ruse.prototype.spoofAttributes = function() {
    var spoof;
    spoof = new Float32Array([0, 0]);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.state1Buffer);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, spoof, this.gl.STATIC_DRAW);
    this.state1Buffer.itemSize = 2;
    this.state1Buffer.numItems = 1;
    this.gl.vertexAttribPointer(this.programs.ruse.points1Attribute, this.state1Buffer.itemSize, this.gl.FLOAT, false, 0, 0);
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.state2Buffer);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, spoof, this.gl.STATIC_DRAW);
    this.state2Buffer.itemSize = 2;
    this.state2Buffer.numItems = 1;
    return this.gl.vertexAttribPointer(this.programs.ruse.points2Attribute, this.state2Buffer.itemSize, this.gl.FLOAT, false, 0, 0);
  };

  Ruse.prototype.scatter3D = function(data) {
    var datum, i, index, margin, max1, max2, max3, min1, min2, min3, nVertices, range1, range2, range3, val1, val2, val3, vertexSize, vertices, _i, _len, _ref;
    console.log('scatter3D');
    mat4.perspective(this.pMatrix, 45.0, this.canvas.width / this.canvas.height, 0.1, 100.0);
    mat4.translate(this.mvMatrix, this.mvMatrix, [0.0, 0.0, -4.5]);
    this.gl.useProgram(this.programs.three);
    this.spoofAttributes();
    margin = this.getMargin();
    vertexSize = 3;
    nVertices = data.length;
    vertices = new Float32Array(vertexSize * nVertices);
    _ref = Object.keys(data[0]), this.key1 = _ref[0], this.key2 = _ref[1], this.key3 = _ref[2];
    i = nVertices;
    min1 = max1 = data[i - 1][this.key1];
    min2 = max2 = data[i - 1][this.key2];
    min3 = max3 = data[i - 1][this.key3];
    while (i--) {
      val1 = data[i][this.key1];
      val2 = data[i][this.key2];
      val3 = data[i][this.key3];
      if (val1 < min1) {
        min1 = val1;
      }
      if (val1 > max1) {
        max1 = val1;
      }
      if (val2 < min2) {
        min2 = val2;
      }
      if (val2 > max2) {
        max2 = val2;
      }
      if (val3 < min3) {
        min3 = val3;
      }
      if (val3 > max3) {
        max3 = val3;
      }
    }
    this.extents = {
      xmin: min1,
      xmax: max1,
      ymin: min2,
      ymax: max2,
      zmin: min3,
      zmax: max3
    };
    this.gl.uniform3f(this.uMinimum, min1, min2, min3);
    this.gl.uniform3f(this.uMaximum, max1, max2, max3);
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
    this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.threeBuffer);
    this.gl.bufferData(this.gl.ARRAY_BUFFER, vertices, this.gl.STATIC_DRAW);
    this.threeBuffer.itemSize = vertexSize;
    this.threeBuffer.numItems = nVertices;
    this.gl.vertexAttribPointer(this.programs.three.vertexPositionAttribute, this.threeBuffer.itemSize, this.gl.FLOAT, false, 0, 0);
    this._setupMouseControls();
    return this.draw3d();
  };

  Ruse.prototype.draw3d = function() {
    mat4.identity(this.mvMatrix);
    mat4.translate(this.mvMatrix, this.mvMatrix, [0.0, 0.0, -4.5]);
    mat4.multiply(this.mvMatrix, this.mvMatrix, this.rotationMatrix);
    this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);
    this._setMatrices(this.programs.three);
    return this.gl.drawArrays(this.gl.POINTS, 0, this.threeBuffer.numItems);
  };

  Shaders = {
    vertex: ["attribute vec3 aPoints1;", "attribute vec3 aPoints2;", "uniform mat4 uMVMatrix;", "uniform mat4 uPMatrix;", "uniform float uMargin;", "uniform vec3 uMinimum1;", "uniform vec3 uMaximum1;", "uniform vec3 uMinimum2;", "uniform vec3 uMaximum2;", "uniform float uTime;", "uniform float uSwitch;", "void main(void) {", "gl_PointSize = 1.25;", "float scaleComponent = 2.0 * (1.0 - uMargin);", "float offsetComponent = (uMargin - 1.0);", "vec3 scale = vec3(scaleComponent, scaleComponent, 0.0);", "vec3 offset = vec3(offsetComponent, offsetComponent, 0.0);", "vec3 range1 = uMaximum1 - uMinimum1;", "vec3 range2 = uMaximum2 - uMinimum2;", "vec3 points1 = scale / range1 * (aPoints1 - uMinimum1) + offset;", "vec3 points2 = scale / range2 * (aPoints2 - uMinimum2) + offset;", "vec3 vertexPosition = (1.0 - abs(uTime - uSwitch)) * points2 + abs(uTime - uSwitch) * points1;", "gl_Position = uPMatrix * uMVMatrix * vec4(vertexPosition, 1.0);", "}"].join("\n"),
    vertex3D: ["attribute vec3 aVertexPosition;", "uniform mat4 uMVMatrix;", "uniform mat4 uPMatrix;", "uniform vec3 uMinimum;", "uniform vec3 uMaximum;", "void main(void) {", "gl_PointSize = 1.25;", "float offsetComponent = -1.0;", "vec3 scale = vec3(2.0, 2.0, 2.0);", "vec3 offset = vec3(-1.0, -1.0, -1.0);", "vec3 range = uMaximum - uMinimum;", "vec3 points = scale / range * (aVertexPosition - uMinimum) + offset;", "gl_Position = uPMatrix * uMVMatrix * vec4(points, 1.0);", "}"].join("\n"),
    fragment: ["precision mediump float;", "void main(void) {", "gl_FragColor = vec4(0.0, 0.4431, 0.8980, 1.0);", "}"].join("\n")
  };

  this.astro.Ruse.Shaders = Shaders;

}).call(this);
