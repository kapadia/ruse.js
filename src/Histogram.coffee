
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
  unless @state is "histogram"
    @switch = 0
    @hasData = false
  @state = "histogram"
  
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
  [min, max] = @getExtent(data)
  
  # Determine optimal bin size unless specified
  unless @bins
    
    # Get width of drawing area
    width = @width - @getMargin() * @width
    
    # Get number of bins able to fit in plot given a target bin width
    @bins = Math.floor(width / @targetBinWidth)
  
  # Compute histogram
  h = @getHistogram(data, min, max, @bins)
  [countMin, countMax] = @getExtent(h)
  
  # Store computed extents for use when creating axes
  @extents =
    xmin: min
    xmax: max
    ymin: countMin
    ymax: countMax
  
  # Generate vertices describing histogram
  margin = @getMargin()
  clipspaceSize = 2.0 - 2 * margin
  
  clipspaceLower = -1.0 + margin
  clipspaceUpper = 1.0 - margin
  
  clipspaceBinWidth = clipspaceSize / @bins
  [histMin, histMax] = @getExtent(h)
  
  vertexSize = 2
  nVertices = 6 * @bins
  vertices = new Float32Array(vertexSize * nVertices)
  
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
  
  [initialBuffer, initialAttribute, finalBuffer, finalAttribute] = @delegateBuffers()
  
  unless @hasData
    @setInitialBuffer(initialBuffer, initialAttribute, vertexSize, nVertices, vertices)
  
  @gl.bindBuffer(@gl.ARRAY_BUFFER, finalBuffer)
  @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
  finalBuffer.itemSize = vertexSize
  finalBuffer.numItems = nVertices
  @gl.vertexAttribPointer(finalAttribute, finalBuffer.itemSize, @gl.FLOAT, false, 0, 0)
  
  @hasData = true
  @drawMode = @gl.TRIANGLES
  @drawAxes()
  @animate()