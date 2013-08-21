
Ruse = @astro.Ruse

Ruse::scatter2D = (data) ->
  @gl.useProgram(@programs.ruse)
  
  # Remove perspective if working in two dimensions
  mat4.identity(@pMatrix)
  mat4.identity(@mvMatrix)
  
  # Compute margin that incorporates spaces needed for axes labels
  margin = @getMargin()
  vertexSize = 2
  
  nVertices = data.length
  vertices = new Float32Array(vertexSize * nVertices)
  
  [@key1, @key2] = Object.keys(data[0])
  
  # Get minimum and maximum for each column
  # TODO: Refactor getExtent to iterate once over multiple equal-sized arrays
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
  
  # Store computed extents for use when creating axes
  @extents =
    xmin: min1
    xmax: max1
    ymin: min2
    ymax: max2
  
  # Update extent on GPU
  if @switch is 0
    uMinimum = @uMinimum1
    uMaximum = @uMaximum1
  else
    uMinimum = @uMinimum2
    uMaximum = @uMaximum2
  
  @gl.uniform3f(uMinimum, min1, min2, 0)
  @gl.uniform3f(uMaximum, max1, max2, 1)
  
  range1 = max1 - min1
  range2 = max2 - min2
  
  for datum, index in data
    i = vertexSize * index
    
    vertices[i] = datum[@key1]
    vertices[i + 1] = datum[@key2]
  
  [initialBuffer, initialAttribute, finalBuffer, finalAttribute] = @delegateBuffers()
  @finalBuffer = finalBuffer
  
  unless @hasData
    
    # Populate initial buffer for animation
    @setInitialBuffer(initialBuffer, initialAttribute, vertexSize, nVertices, vertices)
    
    # Initially send same extent to GPU for each phase
    @gl.uniform3f(@uMinimum1, min1, min2, 0)
    @gl.uniform3f(@uMaximum1, max1, max2, 1)
    
    @gl.uniform3f(@uMinimum2, min1, min2, 0)
    @gl.uniform3f(@uMaximum2, max1, max2, 1)
  
  @gl.bindBuffer(@gl.ARRAY_BUFFER, @finalBuffer)
  @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
  @finalBuffer.itemSize = vertexSize
  @finalBuffer.numItems = nVertices
  @gl.vertexAttribPointer(finalAttribute, @finalBuffer.itemSize, @gl.FLOAT, false, 0, 0)
  
  @hasData = true
  @drawMode = @gl.POINTS
  @drawAxes()
  @animate()