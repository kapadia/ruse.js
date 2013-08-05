
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
    @xOffset = 0
    @yOffset = 0
    
    @axesCanvas.onmousedown = (e) =>
      @drag = true
      @xOldOffset = e.clientX
      @yOldOffset = e.clientY
      
    @axesCanvas.onmouseup = (e) =>
      @drag = false
      
    @axesCanvas.onmousemove = (e) =>
      return unless @drag
      
      x = e.clientX
      y = e.clientY
      
      deltaX = x - @xOldOffset
      deltaY = y - @yOldOffset
      
      deltaXP = @x2xp(deltaX)
      deltaYP = @y2yp(deltaY)
      
      delta = [deltaXP, deltaYP, 0.0]
      mat4.translate(@mvMatrix, @mvMatrix, delta)
      
      @xOldOffset = x
      @yOldOffset = y
      
      @draw()
      
      # Update axes too!
      @xOffset += deltaX
      @yOffset += deltaY
      @drawAxes()
    
    @axesCanvas.onmouseout = (e) =>
      @drag = false
    
    @axesCanvas.onmouseover = (e) =>
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
    # @programs["axes"] = @_createProgram(@gl, shaders.vertex, shaders.fragment)
    
    # Set up camera parameters
    @pMatrix = mat4.create()
    @mvMatrix = mat4.create()
    @rotationMatrix = mat4.create()
    
    mat4.perspective(45.0, @canvas.width / @canvas.height, 0.1, 100.0, @pMatrix)
    mat4.identity(@rotationMatrix)
    mat4.identity(@mvMatrix)
    mat4.translate(@mvMatrix, @mvMatrix, [0.0, 0.0, 0.0])
    
    @_setMatrices(@programs.ruse)
    
    @gl.viewport(0, 0, @width, @height)
    @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)
    @gl.clearDepth(-50.0)
    @gl.depthFunc(@gl.GEQUAL)
    
    @plotBuffer = @gl.createBuffer()
    
    # Plot style parameters
    @margin = 0.02
    @lineWidth = 0.005
    @fontSize = 10
    @fontFamily = "Helvetica"
    @axisPadding = 4
    @xTicks = 6
    @yTicks = 6
    @xTickSize = 4
    @yTickSize = 4
    
    # Plot parameters
    @targetBinWidth = 1  # pixel units
    @bins = null
    @drawMode = null
    
    @_setupMouseControls()
  
  #
  # Draw functions
  #
  
  draw: ->
    @_setMatrices(@programs.ruse)
    @gl.drawArrays(@drawMode, 0, @plotBuffer.numItems)
  
  #
  # Transformation functions
  #
  
  # Denoting primed coordinates as clip space (e.g. xp and yp)
  
  # Pixel units to clip space units
  x2xp: (x) ->
    return 2 / @width * x
  y2yp: (y) ->
    return -2 / @height * y
  
  # Clip space units to pixel units
  xp2x: (xp) ->
    return xp * @width / 2
  yp2y: (yp) ->
    return yp * @height / 2
  
  # Pixel coordinates to clip space coordinates
  xy2xpyp: (x, y) ->
    xp = 2 / @width * x - 1
    yp = -2 / @height * y + 1
    return [xp, yp]
  
  # Clip space coordinates to pixel coordinates
  xpyp2xy: (xp, yp) ->
    x = @width / 2 * (xp + 1)
    y = -@height / 2 * (yp - 1)
    return [x, y]
  
  # Helper methods to check type
  isArray: (obj) ->
    type = Object.prototype.toString.call(obj)
    return if type.indexOf('Array') > -1 then true else false
    
  isObject: (obj) ->
    type = Object.prototype.toString.call(obj)
    return if type.indexOf('Object') > -1 then true else false
  
  # Divide range into equal intervals
  linspace: (start, stop, num) ->
    range = stop - start
    step = range / (num - 1)
    
    steps = new Float32Array(num)
    while num--
      steps[num] = start + num * step
      
    return steps
  
  # Compute the minimum and maximum value of an array with support for NaN values.
  getExtent: (arr) ->
    
    # Set initial values for min and max
    index = arr.length
    while index--
      value = arr[index]
      continue if isNaN(value)
      
      min = max = value
      break
      
    # Continue loop to find extent
    while index--
      value = arr[index]
      
      if isNaN(value)
        continue
        
      if value < min
        min = value
        
      if value > max
        max = value
        
    return [min, max]
  
  # Compute a histogram
  getHistogram: (arr, min, max, bins) ->
    
    range = max - min
    
    h = new Uint32Array(bins)
    dx = range / bins
    
    i = arr.length
    while i--
      value = arr[i]
      index = ~~( (value - min) / dx )
      h[index] += 1
      
    h.dx = dx
    return h
  
  # Draw a histogram.
  histogram: (data) ->
    
    # Data may be formated as an array of one dimensional objects
    # or an array of values
    datum = data[0]
    if @isObject(datum)
      
      # Get key
      key = Object.keys(datum)[0] 
      
      # Parse values from array of objects
      data = data.map( (d) -> d[key] )
    
    #
    # Determine a bin size based on the extent, size of canvas, and target pixel bin width.
    #
    
    # Get the min and max
    [min, max] = @getExtent(data)
    
    # Determine optimal bin size unless specified
    unless @bins
      
      # Get width of drawing area
      width = @width - @getMargin() * @width
      
      # Get number of bins able to fit in plot given a target bin width
      @bins = Math.floor(width / @targetBinWidth)
    
    # Compute histogram
    h = @getHistogram(data, min, max, @bins)
    
    # Generate vertices describing histogram
    margin = @getMargin()
    clipspaceSize = 2.0 - 2 * margin
    
    clipspaceLower = -1.0 + margin
    clipspaceUpper = 1.0 - margin
    
    clipspaceBinWidth = clipspaceSize / @bins
    [histMin, histMax] = @getExtent(h)
    
    nVertices = 6 * @bins
    vertices = new Float32Array(2 * nVertices)
    
    x = -1.0 + margin
    y = y0 = -1.0 + margin
    
    for value, index in h
      i = 12 * index
      
      vertices[i + 0] = x
      vertices[i + 1] = y0
      vertices[i + 2] = x
      vertices[i + 3] = (clipspaceUpper - clipspaceLower) * value / histMax + clipspaceLower
      vertices[i + 4] = x + clipspaceBinWidth
      vertices[i + 5] = y0
      
      vertices[i + 6] = vertices[i + 4]
      vertices[i + 7] = vertices[i + 5]
      vertices[i + 8] = vertices[i + 4]
      vertices[i + 9] = vertices[i + 3]
      vertices[i + 10] = vertices[i + 2]
      vertices[i + 11] = vertices[i + 3]
      
      x += clipspaceBinWidth
    
    @gl.useProgram(@programs.ruse)
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @plotBuffer)
    
    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @plotBuffer.itemSize = 2
    @plotBuffer.numItems = nVertices
    
    @gl.vertexAttribPointer(@programs.ruse.vertexPositionAttribute, @plotBuffer.itemSize, @gl.FLOAT, false, 0, 0)
    
    @drawMode = @gl.TRIANGLES
    @draw()
  
  # Generic call to plot data
  # this function determines the dimensionality of the 
  # data, calling the appropriate function.
  plot: (args...) ->
    
    if args.length is 1
      arg = args[0]
      
      # Check type of argument
      if @isArray(arg)
        
        # Check first element
        datum = arg[0]
        if @isObject(datum)
          
          # Check dimensionality
          keys = Object.keys(datum)
          dimensions = keys.length
          
          switch dimensions
            when 1
              @histogram(arg)
              return
            when 2
              @scatter2D(arg)
              return
            when 3
              @scatter3D(arg)
              return
        else
          # Assuming an array of values
          @histogram(arg)
          return
    
    # Length of arguments is greater than one
    # assume one numerical array per dimension
    
    switch args.length
      when 2
        @scatter2D(args...)
        return
      when 3
        @scatter3D(args...)
        return
    
    # If code gets here, then something wrong with input data
    throw "Input data not recognized by Ruse."
  
  getMargin: ->
    return @margin + (@fontSize + @axisPadding) * 2 / @height
  
  drawAxes: ->
    # Clear the axes canvas
    @axesCanvas.width = @axesCanvas.width
    
    # TODO: Check FPS, might be worth caching context and creating a setup function
    context = @axesCanvas.getContext('2d')
    context.imageSmoothingEnabled = false
    context.lineWidth = 1
    context.translate(@xOffset, @yOffset)
    
    lineWidth = context.lineWidth
    
    # Convert canvas pixel units to clipspace units
    lineWidthX = lineWidth * 2 / @width
    lineWidthY = lineWidth * 2 / @height
    
    margin = @getMargin()
    
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
      
      [x, y] = @xpyp2xy(xp, yp)
      vertices[i] = x
      vertices[i + 1] = y
    
    context.beginPath()
    context.moveTo(vertices[0], vertices[1])
    context.lineTo(vertices[2], vertices[3])
    context.closePath()
    context.stroke()
    
    context.beginPath()
    context.moveTo(vertices[4], vertices[5])
    context.lineTo(vertices[6], vertices[7])
    context.closePath()
    context.stroke()
    
    # Tick marks
    [x1, y1] = @xpyp2xy(-1.0 + margin, -1.0 + margin)
    [x2, y2] = @xpyp2xy(1.0 - margin, 1.0 - margin)
    xTicks = @linspace(x1, x2, @xTicks + 1).subarray(1)
    yTicks = @linspace(y1, y2, @yTicks + 1).subarray(1)
    
    for xTick in xTicks
      context.beginPath()
      context.moveTo(xTick, y1)
      context.lineTo(xTick, y1 - @xTickSize)
      context.stroke()
    
    for yTick in yTicks
      context.beginPath()
      context.moveTo(x1 - 1, yTick)
      context.lineTo(x1 - 1 + @yTickSize, yTick)
      context.stroke()
    
    # Axes names
    context.font = "#{@fontSize}px #{@fontFamily}"
    
    key1width = context.measureText(@key1).width
    key2width = context.measureText(@key2).width
    
    # Measurements for x axis
    [x, y] = @xpyp2xy(1.0 - margin, -1.0 + margin)
    x -= key1width
    y += @fontSize + 4
    context.fillText("#{@key1}", x, y)
    
    # Measurements for y axis
    context.save()
    context.rotate(-Math.PI / 2)
    x = -1 * (margin * @height / 2 + key2width)
    y = margin * @width / 2 - @fontSize
    context.fillText("#{@key2}", x, y)
    context.restore()
  
  scatter2D: (data) ->
    
    # Should be able to accept data in various formats
    # e.g. [{key1: val1, key2: val2}, ...]
    # two arrays
    
    @gl.useProgram(@programs.ruse)
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @plotBuffer)
    
    # Compute margin that incorporates spaces needed for axes labels
    margin = @getMargin()
    
    nVertices = data.length
    vertices = new Float32Array(2 * nVertices)
    
    [@key1, @key2] = Object.keys(data[0])
    
    # Get minimum and maximum for each column
    i = nVertices
    min1 = max1 = data[i - 1][@key1]
    min2 = max2 = data[i - 1][@key2]
    while i--
      val1 = data[i][@key1]
      val2 = data[i][@key2]
      
      min1 = val1 if val1 < min1
      max1 = val1 if val1 > max1
      
      min2 = val2 if val2 < min2
      max2 = val2 if val2 > max2
    
    range1 = max1 - min1
    range2 = max2 - min2
    
    for datum, index in data
      i = 2 * index
      val1 = datum[@key1]
      val2 = datum[@key2]
      
      vertices[i] = 2 * (1 - margin) / range1 * (val1 - min1) - 1 + margin
      vertices[i + 1] = 2 * (1 - margin) / range2 * (val2 - min2) - 1 + margin
    
    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @plotBuffer.itemSize = 2
    @plotBuffer.numItems = nVertices
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @plotBuffer)
    @gl.vertexAttribPointer(@programs.ruse.vertexPositionAttribute, @plotBuffer.itemSize, @gl.FLOAT, false, 0, 0)
    
    @drawMode = @gl.POINTS
    @draw()
    @drawAxes()
    
  scatter3D: (data) ->
    throw "scatter3D not yet implemented"
    
    @gl.useProgram(@programs.ruse)
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @plotBuffer)
    
    # # Compute margin that incorporates spaces needed for axes labels
    # margin = @getMargin()
    # 
    # nVertices = data.length
    # vertices = new Float32Array(3 * nVertices)
    # 
    # [key1, key2, key3] = Object.keys(data[0])
    # 
    # # Get minimum and maximum for each column
    # # TODO: Refactor getExtent to iterate over array of objects
    # i = nVertices
    # min1 = max1 = data[i - 1][key1]
    # min2 = max2 = data[i - 1][key2]
    # min3 = max3 = data[i - 1][key3]
    # while i--
    #   val1 = data[i][key1]
    #   val2 = data[i][key2]
    #   val3 = data[i][key3]
    #   
    #   min1 = val1 if val1 < min1
    #   max1 = val1 if val1 > max1
    #   
    #   min2 = val2 if val2 < min2
    #   max2 = val2 if val2 > max2
    #   
    #   min3 = val3 if val3 < min3
    #   max3 = val3 if val3 > max3
    # 
    # range1 = max1 - min1
    # range2 = max2 - min2
    # range3 = max3 - min3
    # 
    # for datum, index in data
    #   i = 3 * index
    #   val1 = datum[key1]
    #   val2 = datum[key2]
    #   val3 = datum[key3]
    #   
    #   vertices[i] = 2 * (1 - margin) / range1 * (val1 - min1) - 1 + margin
    #   vertices[i + 1] = 2 * (1 - margin) / range2 * (val2 - min2) - 1 + margin
    #   vertices[i + 3] = 2 * (1 - margin) / range3 * (val3 - min3) - 1 + margin
    
    nVertices = 1
    vertices = new Float32Array([0.0, 0.0, 1.0])
    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @plotBuffer.itemSize = 3
    @plotBuffer.numItems = nVertices
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @plotBuffer)
    @gl.vertexAttribPointer(@programs.ruse.vertexPositionAttribute, @plotBuffer.itemSize, @gl.FLOAT, false, 0, 0)
    
    @drawMode = @gl.POINTS
    @draw()
    @drawAxes()


@astro = {} unless @astro?
@astro.Ruse = Ruse
@astro.Ruse.version = '0.1.0'