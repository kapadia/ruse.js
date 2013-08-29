
Ruse = @astro.Ruse

# Font size is units of pixels
Ruse::setFontSize = (value) ->
  @fontSize = value
  @drawAxes()

# Compute a histogram in one pass
Ruse::getHistogram = (arr, min, max, bins) ->
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
Ruse::histogram = (data) ->
  @gl.useProgram(@programs.ruse)
  
  unless @state is "histogram"
    @switch = 0
    @hasData = false
  @state = "histogram"
  
  # TODO: Abstract some setup code since repeated across all plots
  @gl.uniform1f(@uZComponent, 0.0)
  
  # Remove perspective if working in two dimensions
  mat4.identity(@pMatrix)
  mat4.identity(@mvMatrix)
  mat4.identity(@rotationMatrix)
  @translateBy = [0.0, 0.0, 0.0]
  
  # Compute margin that incorporates spaces needed for axes labels
  margin = @getMargin()
  
  # Data may be formated as an array of one dimensional objects
  # or an array of values
  datum = data[0]
  if @isObject(datum)
    
    # Get key
    key = Object.keys(datum)[0] 
    
    # Define keys for makeAxes function
    @key1 = key
    @key2 = ""
    
    # Parse values from array of objects
    data = data.map( (d) -> d[key] )
  
  #
  # Determine a bin size based on the extent, size of canvas, and target pixel bin width.
  #
  
  # Get the min and max
  [dataMin, dataMax] = @getExtent(data)
  
  # Determine optimal bin size unless specified
  unless @bins
    
    # Get width of drawing area
    width = @width - @getMargin() * @width
    
    # Get number of bins able to fit in plot given a target bin width
    @bins = Math.floor(width / @targetBinWidth)
  
  # Compute histogram
  h = @getHistogram(data, dataMin, dataMax, @bins)
  [histMin, histMax] = @getExtent(h)
  
  # Generate vertices describing histogram
  clipspaceSize = 2.0
  clipspaceBinWidth = clipspaceSize / @bins
  
  clipspaceLower = -1.0
  clipspaceUpper = 1.0
  
  vertexSize = 2
  nVertices = 6 * @bins
  vertices = new Float32Array(vertexSize * nVertices)
  
  x = -1.0
  y = y0 = -1.0
  
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
  
  unless @hasData
    initialVertices = new Float32Array(vertexSize * nVertices)
    for datum, i in vertices by 2
      initialVertices[i] = datum
      initialVertices[i + 1] = -1.0
      
    # Upload initial buffer array to GPU
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @dataBuffer1)
    @gl.bufferData(@gl.ARRAY_BUFFER, initialVertices, @gl.STATIC_DRAW)
    
    # Store computed extents for use when creating axes
    # This is stored here so that following code perceives it as previous values
    @extents =
      xmin: dataMin
      xmax: dataMax
      ymin: histMin
      ymax: histMax
    
    @hasData = true
  
  
  @dataBuffer1.itemSize = vertexSize
  @dataBuffer1.numItems = nVertices

  @dataBuffer2.itemSize = vertexSize
  @dataBuffer2.numItems = nVertices
  
  # Bind previous extents to uMinimum1 and uMaximum2
  @gl.uniform3f(@uMinimum1, -1, -1, 0)
  @gl.uniform3f(@uMaximum1, 1, 1, 1)
  
  # Bind current extents to uMinimum2 and uMaximum2
  @gl.uniform3f(@uMinimum2, -1, -1, 0)
  @gl.uniform3f(@uMaximum2, 1, 1, 1)
  
  # Upload new data to appropriate buffer and delegate attribute pointers based according to switch
  if @switch is 0
    #
    # Data transitions from aVertexPosition1 to aVertexPosition2
    #
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @dataBuffer1)
    @gl.vertexAttribPointer(@programs.ruse.aVertexPosition1, @dataBuffer1.itemSize, @gl.FLOAT, false, 0, 0)
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @dataBuffer2)
    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @gl.vertexAttribPointer(@programs.ruse.aVertexPosition2, @dataBuffer2.itemSize, @gl.FLOAT, false, 0, 0)
    
    @switch = 1
  else
    
    #
    # Data transitions from aVertexPosition2 to aVertexPosition1
    #
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @dataBuffer1)
    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @gl.vertexAttribPointer(@programs.ruse.aVertexPosition1, @dataBuffer1.itemSize, @gl.FLOAT, false, 0, 0)
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @dataBuffer2)
    @gl.vertexAttribPointer(@programs.ruse.aVertexPosition2, @dataBuffer2.itemSize, @gl.FLOAT, false, 0, 0)
    
    @switch = 0
  
  # Store computed extents for use when creating axes
  @extents =
    xmin: dataMin
    xmax: dataMax
    ymin: histMin
    ymax: histMax
  
  @drawAxes()
  @drawMode = @gl.TRIANGLES
  @axesCanvas.onmousemove = null
  @animate()