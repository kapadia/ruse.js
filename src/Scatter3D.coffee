
Ruse = @astro.Ruse

# Attributes are peculiar.  Each attribute across all programs *must* be associated with a buffer.
# Associate with junk data for now.
Ruse::spoofAttributes = ->
  
  spoof = new Float32Array([0, 0])
  
  @gl.bindBuffer(@gl.ARRAY_BUFFER, @state1Buffer)
  @gl.bufferData(@gl.ARRAY_BUFFER, spoof, @gl.STATIC_DRAW)
  @state1Buffer.itemSize = 2
  @state1Buffer.numItems = 1
  @gl.vertexAttribPointer(@programs.ruse.points1Attribute, @state1Buffer.itemSize, @gl.FLOAT, false, 0, 0)
  
  @gl.bindBuffer(@gl.ARRAY_BUFFER, @state2Buffer)
  @gl.bufferData(@gl.ARRAY_BUFFER, spoof, @gl.STATIC_DRAW)
  @state2Buffer.itemSize = 2
  @state2Buffer.numItems = 1
  @gl.vertexAttribPointer(@programs.ruse.points2Attribute, @state2Buffer.itemSize, @gl.FLOAT, false, 0, 0)


Ruse::scatter3D = (data) ->
  
  # Add perspective when working in three dimensions
  mat4.perspective(@pMatrix, 45.0, 1.0, 0.1, 100.0)
  
  @gl.useProgram(@programs.three)
  @spoofAttributes()
  
  # Proceed to handling the real data
  
  # Compute margin that incorporates spaces needed for axes labels
  margin = @getMargin()
  vertexSize = 3
  
  nVertices = data.length
  vertices = new Float32Array(vertexSize * nVertices)
  initialVertices = new Float32Array(vertexSize * nVertices)
  
  [@key1, @key2, @key3] = Object.keys(data[0])
  
  # Get minimum and maximum for each column
  # TODO: Refactor getExtent to iterate once over multiple equal-sized arrays
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
  
  range1 = max1 - min1
  range2 = max2 - min2
  range3 = max3 - min3
  
  for datum, index in data
    i = vertexSize * index
    
    vertices[i] = initialVertices[i] = datum[@key1]
    vertices[i + 1] = initialVertices[i + 1] = datum[@key2]
    vertices[i + 2] = datum[@key3]
  
  unless @hasData3d
    # NOTE: Another solution for the initial vertices is to create a GL program that is 
    #       run only once to run on the initial upload of data.  Subsequent plots will use
    #       another shader program that is created for transitions between buffers.  This is possible
    #       because programs can share buffers (i think ...).  This would provide a more memory efficient
    #       solution, as only one typed array needs to be initialized on the client.
    for datum, index in data
      i = vertexSize * index
      initialVertices[i + 2] = 0
    
    # Upload initial buffer array to GPU
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @threeBuffer1)
    @gl.bufferData(@gl.ARRAY_BUFFER, initialVertices, @gl.STATIC_DRAW)
    
    # Store computed extents for use when creating axes
    # This is stored here so that code below perceives it as previous values
    @extents =
      xmin: min1
      xmax: max1
      ymin: min2
      ymax: max2
      zmin: min3
      zmax: max3
    
    @hasData3d = true
  
  @threeBuffer1.itemSize = vertexSize
  @threeBuffer1.numItems = nVertices
  
  @threeBuffer2.itemSize = vertexSize
  @threeBuffer2.numItems = nVertices
  
  # Upload new data to appropriate buffer and delegate attribute pointers based according to switch
  if @switch3d is 0
    
    #
    # Data transitions from aVertexPosition1 to aVertexPosition2
    #
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @threeBuffer1)
    @gl.vertexAttribPointer(@programs.three.vertexPosition1Attribute, @threeBuffer1.itemSize, @gl.FLOAT, false, 0, 0)
    
    # Bind previous extents to uMinimum1 and uMaximum2
    @gl.uniform3f(@uMinimum3d1, @extents.xmin, @extents.ymin, @extents.zmin)
    @gl.uniform3f(@uMaximum3d1, @extents.xmax, @extents.ymax, @extents.zmax)
    
    # Bind current extents to uMinimum2 and uMaximum2
    @gl.uniform3f(@uMinimum3d2, min1, min2, min3)
    @gl.uniform3f(@uMaximum3d2, max1, max2, max3)
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @threeBuffer2)
    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @gl.vertexAttribPointer(@programs.three.vertexPosition2Attribute, @threeBuffer2.itemSize, @gl.FLOAT, false, 0, 0)
    
    @switch3d = 1
  else
    #
    # Data transitions from aVertexPosition2 to aVertexPosition1
    #
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @threeBuffer1)
    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @gl.vertexAttribPointer(@programs.three.vertexPosition1Attribute, @threeBuffer1.itemSize, @gl.FLOAT, false, 0, 0)
    
    # Bind current extents to uMinimum1 and uMaximum2
    @gl.uniform3f(@uMinimum3d1, min1, min2, min3)
    @gl.uniform3f(@uMaximum3d1, max1, max2, max3)
    
    # Bind previous extents to uMinimum2 and uMaximum2
    @gl.uniform3f(@uMinimum3d2, @extents.xmin, @extents.ymin, @extents.zmin)
    @gl.uniform3f(@uMaximum3d2, @extents.xmax, @extents.ymax, @extents.zmax)
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @threeBuffer2)
    @gl.vertexAttribPointer(@programs.three.vertexPosition2Attribute, @threeBuffer2.itemSize, @gl.FLOAT, false, 0, 0)
    
    @switch3d = 0
  
  # Update computed extents for current data
  @extents =
    xmin: min1
    xmax: max1
    ymin: min2
    ymax: max2
    zmin: min3
    zmax: max3
  
  @_setupMouseControls()
  @animate3d()

Ruse::draw3d = ->
  
  mat4.identity(@mvMatrix)
  mat4.translate(@mvMatrix, @mvMatrix, [0.0, 0.0, -4.0])
  mat4.multiply(@mvMatrix, @mvMatrix, @rotationMatrix)
  @_setMatrices(@programs.three)
  
  @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)
  @gl.drawArrays(@gl.POINTS, 0, @threeBuffer1.numItems)
  
Ruse::animate3d = ->
  @gl.useProgram(@programs.three)
  
  i = 0
  intervalId = setInterval( =>
    i += 1
    uTime = if @switch3d is 1 then i / 150 else 1 - i / 150
    @gl.uniform1f(@uTime3d, uTime)
    @draw3d()
    if i is 150
      clearInterval(intervalId)
  , 1000 / 60)