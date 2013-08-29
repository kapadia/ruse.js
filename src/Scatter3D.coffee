
Ruse = @astro.Ruse


Ruse::scatter3D = (data) ->
  @gl.useProgram(@programs.ruse)
  
  unless @state is "scatter3D"
    @switch = 0
    @hasData = false
  @state = "scatter3D"
  
  # Add perspective when working in three dimensions
  mat4.perspective(@pMatrix, 45.0, 1.0, 0.1, 100.0)
  @translateBy = [0.0, 0.0, -4.0]
  
  @gl.uniform1f(@uZComponent, 1.0)
  
  # Proceed to handling the real data
  
  vertexSize = 3
  nVertices = data.length
  vertices = new Float32Array(vertexSize * nVertices)
  
  [@key1, @key2, @key3] = Object.keys(data[0])
  [ [min1, min2, min3], [max1, max2, max3] ] = @getExtentFromObjects(data)
  
  range1 = max1 - min1
  range2 = max2 - min2
  range3 = max3 - min3
  
  for datum, index in data
    i = vertexSize * index
    
    vertices[i] = datum[@key1]
    vertices[i + 1] = datum[@key2]
    vertices[i + 2] = datum[@key3]
  
  unless @hasData
    # NOTE: Another solution for the initial vertices is to create a GL program that is 
    #       run only once on the initial upload of data.  Subsequent plots will use
    #       another shader program that is created for transitions between buffers.  This is possible
    #       because programs can share buffers (i think ...).  This would provide a more memory efficient
    #       solution, as only one typed array needs to be initialized on the client.s
    initialVertices = new Float32Array(vertexSize * nVertices)
    for datum, index in data
      i = vertexSize * index
      initialVertices[i] = datum[@key1]
      initialVertices[i + 1] = datum[@key2]
      initialVertices[i + 2] = 0
    
    # Upload initial buffer array to GPU
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @dataBuffer1)
    @gl.bufferData(@gl.ARRAY_BUFFER, initialVertices, @gl.STATIC_DRAW)
    
    # Store computed extents for use when creating axes
    # This is stored here so that following code perceives it as previous values
    @extents =
      xmin: min1
      xmax: max1
      ymin: min2
      ymax: max2
      zmin: min3
      zmax: max3
    
    @hasData = true
  
  @dataBuffer1.itemSize = vertexSize
  @dataBuffer1.numItems = nVertices
  
  @dataBuffer2.itemSize = vertexSize
  @dataBuffer2.numItems = nVertices
  
  # Upload new data to appropriate buffer and delegate attribute pointers based according to switch
  if @switch is 0
    
    #
    # Data transitions from aVertexPosition1 to aVertexPosition2
    #
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @dataBuffer1)
    @gl.vertexAttribPointer(@programs.ruse.aVertexPosition1, @dataBuffer1.itemSize, @gl.FLOAT, false, 0, 0)
    
    # Bind previous extents to uMinimum1 and uMaximum2
    @gl.uniform3f(@uMinimum1, @extents.xmin, @extents.ymin, @extents.zmin)
    @gl.uniform3f(@uMaximum1, @extents.xmax, @extents.ymax, @extents.zmax)
    
    # Bind current extents to uMinimum2 and uMaximum2
    @gl.uniform3f(@uMinimum2, min1, min2, min3)
    @gl.uniform3f(@uMaximum2, max1, max2, max3)
    
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
    
    # Bind current extents to uMinimum1 and uMaximum2
    @gl.uniform3f(@uMinimum1, min1, min2, min3)
    @gl.uniform3f(@uMaximum1, max1, max2, max3)
    
    # Bind previous extents to uMinimum2 and uMaximum2
    @gl.uniform3f(@uMinimum2, @extents.xmin, @extents.ymin, @extents.zmin)
    @gl.uniform3f(@uMaximum2, @extents.xmax, @extents.ymax, @extents.zmax)
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @dataBuffer2)
    @gl.vertexAttribPointer(@programs.ruse.aVertexPosition2, @dataBuffer2.itemSize, @gl.FLOAT, false, 0, 0)
    
    @switch = 0
  
  # Update computed extents for current data
  @extents =
    xmin: min1
    xmax: max1
    ymin: min2
    ymax: max2
    zmin: min3
    zmax: max3
    
  @_setupMouseControls()
  @removeAxes()
  @drawMode = @gl.POINTS
  @animate()
