
class Ruse
  
  
  _loadShader: (gl, source, type) ->
    
    shader = gl.createShader(type)
    gl.shaderSource(shader, source)
    gl.compileShader(shader)
    
    compiled = gl.getShaderParameter(shader, gl.COMPILE_STATUS)
    unless compiled
      lastError = gl.getShaderInfoLog(shader)
      throw "Error compiling shader #{shader}: #{lastError}"
      gl.deleteShader(shader)
      return null
    
    return shader
  
  _createProgram: (gl, vertexShader, fragmentShader) ->
    vertexShader = @_loadShader(gl, vertexShader, gl.VERTEX_SHADER)
    fragmentShader = @_loadShader(gl, fragmentShader, gl.FRAGMENT_SHADER)
    
    program = gl.createProgram()
    
    gl.attachShader(program, vertexShader)
    gl.attachShader(program, fragmentShader)
    gl.linkProgram(program)
    
    linked = gl.getProgramParameter(program, gl.LINK_STATUS)
    unless linked
      throw "Error in program linking: #{gl.getProgramInfoLog(program)}"
      gl.deleteProgram(program)
      return null
    
    gl.useProgram(program)
    
    program.vertexPositionAttribute = gl.getAttribLocation(program, "aVertexPosition")
    gl.enableVertexAttribArray(program.vertexPositionAttribute)
    
    program.uPMatrix = gl.getUniformLocation(program, "uPMatrix")
    program.uMVMatrix = gl.getUniformLocation(program, "uMVMatrix")
    
    return program
  
  _setMatrices: (program) ->
    @gl.useProgram(program)
    @gl.uniformMatrix4fv(program.uPMatrix, false, @pMatrix)
    @gl.uniformMatrix4fv(program.uMVMatrix, false, @mvMatrix)
  
  _toRadians: (deg) ->
    return deg * 0.017453292519943295
  
  _setupMouseControls: ->
    
    @drag = false
    @xOldOffset = null
    @yOldOffset = null
    
    @canvas.onmousedown = (e) =>
      @drag = true
      @xOldOffset = e.clientX
      @yOldOffset = e.clientY
      
    @canvas.onmouseup = (e) =>
      @drag = false
      
    @canvas.onmousemove = (e) =>
      return unless @drag
      
      x = e.clientX
      y = e.clientY
      
      deltaX = x - @xOldOffset
      deltaY = y - @yOldOffset
      
      rotationMatrix = mat4.create()
      mat4.identity(rotationMatrix)
      mat4.rotateY(rotationMatrix, rotationMatrix, @_toRadians(deltaX / 4))
      mat4.rotateX(rotationMatrix, rotationMatrix, @_toRadians(deltaY / 4))
      mat4.multiply(@rotationMatrix, rotationMatrix, @rotationMatrix)
      
      @xOldOffset = x
      @yOldOffset = y
      
      @draw()
    
    @canvas.onmouseout = (e) =>
      @drag = false
    
    @canvas.onmouseover = (e) =>
      @drag = false
  
  constructor: (arg, width, height) ->
    
    # Either initialize a WebGL context or utilize an existing one
    s = arg.constructor.toString()
    if s.indexOf('WebGLRenderingContext') > -1 or s.indexOf('rawgl') > -1
      @gl = arg
      @canvas = arg.canvas
      @width = @canvas.width
      @height = @canvas.height
      @canvas.style.position = 'absolute'
    else
      # Assume we have a DOM element and width and height have been provided
      @width = width
      @height = height
      
      # Create and attach canvas to DOM
      @canvas = document.createElement('canvas')
      @canvas.setAttribute('width', @width)
      @canvas.setAttribute('height', @height)
      @canvas.setAttribute('class', 'ruse')
      @canvas.style.position = 'absolute'
      
      @gl = @canvas.getContext('webgl') or canvas.getContext('experimental-webgl')
      return null unless @gl
      
      arg.appendChild(@canvas)
    
    # Initialize a secondary canvas for axes and ticks
    @axesCanvas = document.createElement('canvas')
    @axesCanvas.setAttribute('width', @width)
    @axesCanvas.setAttribute('height', @height)
    @axesCanvas.setAttribute('class', 'ruse axes')
    @axesCanvas.style.position = 'absolute'
    @gl.canvas.parentElement.appendChild(@axesCanvas)
    
    # Initialize programs from shaders
    shaders = @constructor.Shaders
    @programs = {}
    @programs["ruse"] = @_createProgram(@gl, shaders.vertex, shaders.fragment)
    @programs["axes"] = @_createProgram(@gl, shaders.vertex, shaders.fragment)
    
    # Set up camera parameters
    @pMatrix = mat4.create()
    @mvMatrix = mat4.create()
    @rotationMatrix = mat4.create()
    
    mat4.perspective(45.0, @canvas.width / @canvas.height, 0.1, 100.0, @pMatrix)
    mat4.identity(@rotationMatrix)
    mat4.identity(@mvMatrix)
    
    @_setMatrices(@programs.ruse)
    # @_setMatrices(@programs.axes)
    
    @gl.viewport(0, 0, @width, @height)
    @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)
    
    @plotBuffer = @gl.createBuffer()
    @axesBuffer = @gl.createBuffer()
    
    # Plot parameters
    @margin = 0.02
    @lineWidth = 0.005
    @fontSize = 9
    @fontFamily = "Helvetica Neue"
    @axisPadding = 4
    
    # @_setupMouseControls()
  
  _canvas2clipspace: (x, y) ->
    xp = 2 / @width * x - 1
    yp = -2 / @height * y + 1
    return [xp, yp]
  
  _clipspace2canvas: (xp, yp) ->
    x = @width / 2 * (xp + 1)
    y = -@height / 2 * (yp - 1)
    return [x, y]
  
  draw: ->
    mat4.identity(@mvMatrix)
    mat4.translate(@mvMatrix, @mvMatrix, [0.0, 0.0, 0.0])
    mat4.multiply(@mvMatrix, @mvMatrix, @rotationMatrix)
    mat4.translate(@mvMatrix, @mvMatrix, [-0.5, -0.5, -0.5])
    
    @_setMatrices(@programs.ruse)
    @gl.drawArrays(@gl.POINTS, 0, @plotBuffer.numItems)
    # @_setMatrices(@programs.axes)
    # @gl.drawArrays(@gl.TRIANGLES, 0, @axesBuffer.numItems)
  
  plot: (rows) ->
    @_scatter2D(rows)
    
    [key1, key2] = Object.keys( rows[0] )
    @_makeAxes(key1, key2)
  
  _makeAxesGl: (key1, key2) ->
    margin = @margin
    lineWidth = @lineWidth
    
    @gl.useProgram(@programs.axes)
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @axesBuffer)
    
    nVertices = 12
    vertices = new Float32Array([
      
      # y axis
      -1.0 + @margin, 1.0,
      -1.0 + @margin - lineWidth, 1.0,
      -1.0 + @margin - lineWidth, -1.0,
      
      -1.0 + @margin - lineWidth, -1.0,
      -1.0 + @margin, -1.0,
      -1.0 + @margin, 1.0,
      
      # x axis
      -1.0, -1.0 + @margin,
      1.0, -1.0 + @margin,
      -1.0, -1.0 + @margin - lineWidth,
      
      -1.0, -1.0 + @margin - lineWidth,
      1.0, -1.0 + @margin - lineWidth,
      1.0, -1.0 + @margin
    ])
    
    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @axesBuffer.itemSize = 2
    @axesBuffer.numItems = nVertices
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @axesBuffer)
    @gl.vertexAttribPointer(@programs.axes.vertexPositionAttribute, @axesBuffer.itemSize, @gl.FLOAT, false, 0, 0)
    @gl.drawArrays(@gl.TRIANGLES, 0, @axesBuffer.numItems)
  
  _getMargin: ->
    return @margin + (@fontSize + @axisPadding) * 2 / @height
  
  _makeAxes: (key1, key2) ->
    context = @axesCanvas.getContext('2d')
    context.imageSmoothingEnabled = false
    context.lineWidth = 1
    
    lineWidth = context.lineWidth
    
    # Convert canvas pixel units to clipspace units
    lineWidthX = lineWidth * 2 / @width
    lineWidthY = lineWidth * 2 / @height
    
    margin = @_getMargin()
    
    # Determine axes given margin and line width
    vertices = new Float32Array([
      # y axis
      -1.0 + margin - lineWidthX, 1.0,
      -1.0 + margin - lineWidthX, -1.0,
      
      # x axis
      -1.0, -1.0 + margin - lineWidthY,
      1.0, -1.0 + margin - lineWidthY
    ])
    
    # Transform to canvas coordinates
    for value, i in vertices by 2
      xp = vertices[i]
      yp = vertices[i + 1]
      
      [x, y] = @_clipspace2canvas(xp, yp)
      vertices[i] = x
      vertices[i + 1] = y
    
    context.beginPath()
    context.moveTo(vertices[0], vertices[1])
    context.lineTo(vertices[2], vertices[3])
    context.stroke()
    
    context.beginPath()
    context.moveTo(vertices[4], vertices[5])
    context.lineTo(vertices[6], vertices[7])
    context.stroke()
    
    # Axes names
    context.font = "#{@fontSize}px #{@fontFamily}"
    
    key1width = context.measureText(key1).width
    key2width = context.measureText(key2).width
    
    # Measurements for x axis
    [x, y] = @_clipspace2canvas(1.0 - margin, -1.0 + margin)
    x -= key1width
    y += @fontSize + 4
    context.fillText("#{key1}", x, y)
    
    # Measurements for y axis
    context.save()
    context.rotate(-Math.PI / 2)
    x = -1 * (margin * @height / 2 + key2width)
    y = margin * @width / 2 - @fontSize
    context.fillText("#{key2}", x, y)
    context.restore()
  
  _scatter2D: (data) ->
    
    # Should be able to accept data in various formats
    # e.g. [{key1: val1, key2: val2}, ...]
    # two arrays
    # object with two keys and arrays?
    
    @gl.useProgram(@programs.ruse)
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @plotBuffer)
    
    # Compute margin that incorporates spaces needed for axes labels
    margin = @_getMargin()
    
    nVertices = data.length
    vertices = new Float32Array(2 * nVertices)
    
    [key1, key2] = Object.keys(data[0])
    
    # Get minimum and maximum for each column
    i = nVertices
    min1 = max1 = data[i - 1][key1]
    min2 = max2 = data[i - 1][key2]
    while i--
      val1 = data[i][key1]
      val2 = data[i][key2]
      
      min1 = val1 if val1 < min1
      max1 = val1 if val1 > max1
      
      min2 = val2 if val2 < min2
      max2 = val2 if val2 > max2
    
    range1 = max1 - min1
    range2 = max2 - min2
    
    for datum, index in data
      i = 2 * index
      val1 = datum[key1]
      val2 = datum[key2]
      
      vertices[i] = 2 * (1 - margin) / range1 * (val1 - min1) - 1 + margin
      vertices[i + 1] = 2 * (1 - margin) / range2 * (val2 - min2) - 1 + margin
    
    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @plotBuffer.itemSize = 2
    @plotBuffer.numItems = nVertices
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @plotBuffer)
    @gl.vertexAttribPointer(@programs.ruse.vertexPositionAttribute, @plotBuffer.itemSize, @gl.FLOAT, false, 0, 0)
    @gl.drawArrays(@gl.POINTS, 0, @plotBuffer.numItems)


@astro = {} unless @astro?
@astro.Ruse = Ruse
@astro.Ruse.version = '0.1.0'