
Ruse = @astro.Ruse

Ruse::scatter3D = (data) ->
  console.log 'scatter3D'
  @gl.useProgram(@programs.ruse)
  
  # Compute margin that incorporates spaces needed for axes labels
  margin = @getMargin()
  vertexSize = 3
  
  nVertices = data.length
  vertices = new Float32Array(vertexSize * nVertices)
  
  [@key1, @key2, @key3] = Object.keys(data[0])
  
  # Get minimum and maximum for each column
  # TODO: Refactor getExtent to iterate once over multiple equal-sized arrays
  # TODO: This is nearly exact code as in scatter2D function.  Generalize.
  i = nVertices
  min1 = max1 = data[i - 1][@key1]
  min2 = max2 = data[i - 1][@key2]
  min3 = max3 = data[i - 1][@key3]
  while i--
    val1 = data[i][@key1]
    val2 = data[i][@key2]
    val3 = data[i][@key3]
    
    min1 = val1 if val1 < min1
    max1 = val1 if val1 > max1
    
    min2 = val2 if val2 < min2
    max2 = val2 if val2 > max2
    
    min3 = val3 if val3 < min3
    max3 = val3 if val3 > max3
  
  # Store computed extents for use when creating axes
  @extents =
    xmin: min1
    xmax: max1
    ymin: min2
    ymax: max2
    zmin: min3
    zmax: max3
  
  # Update extent on GPU
  if @switch is 0
    uMinimum = @uMinimum1
    uMaximum = @uMaximum1
  else
    uMinimum = @uMinimum2
    uMaximum = @uMaximum2
  
  console.log min1, min2, min3
  console.log max1, max2, max3
  @gl.uniform3f(uMinimum, min1, min2, min3)
  @gl.uniform3f(uMaximum, max1, max2, max3)
  
  range1 = max1 - min1
  range2 = max2 - min2
  range3 = max3 - min3
  
  for datum, index in data
    i = vertexSize * index
    
    vertices[i] = datum[@key1]
    vertices[i + 1] = datum[@key2]
    vertices[i + 2] = datum[@key3]
  
  [initialBuffer, initialAttribute, finalBuffer, finalAttribute] = @delegateBuffers()
  @finalBuffer = finalBuffer
  
  unless @hasData
    
    # Populate initial buffer for animation
    @setInitialBuffer(initialBuffer, initialAttribute, vertexSize, nVertices, vertices)
    
    # Initially send same extent to GPU for each phase
    @gl.uniform3f(@uMinimum1, min1, min2, min3)
    @gl.uniform3f(@uMaximum1, max1, max2, max3)
    
    @gl.uniform3f(@uMinimum2, min1, min2, min3)
    @gl.uniform3f(@uMaximum2, max1, max2, max3)
    
  @gl.bindBuffer(@gl.ARRAY_BUFFER, @finalBuffer)
  @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
  @finalBuffer.itemSize = vertexSize
  @finalBuffer.numItems = nVertices
  @gl.vertexAttribPointer(finalAttribute, @finalBuffer.itemSize, @gl.FLOAT, false, 0, 0)
  
  @hasData = true
  @drawMode = @gl.POINTS
  @animate()