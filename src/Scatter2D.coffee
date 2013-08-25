
Ruse = @astro.Ruse

Ruse::scatter2D = (data) ->
  unless @state is "scatter2D"
    @switch = 0
    @hasData = false
  @state = "scatter2D"
  
  @gl.useProgram(@programs.ruse)
  @gl.uniform1f(@uZComponent, 0.0)
  
  # Remove perspective if working in two dimensions
  mat4.identity(@pMatrix)
  mat4.identity(@mvMatrix)
  mat4.identity(@rotationMatrix)
  @translateBy = [0.0, 0.0, 0.0]
  
  # Compute margin that incorporates spaces needed for axes labels
  margin = @getMargin()
  
  vertexSize = 2
  nVertices = data.length
  vertices = new Float32Array(vertexSize * nVertices)
  
  [@key1, @key2] = Object.keys(data[0])
  [ [min1, min2], [max1, max2] ] = @getExtentFromObjects(data)
  
  range1 = max1 - min1
  range2 = max2 - min2
  
  for datum, index in data
    i = vertexSize * index
    
    vertices[i] = datum[@key1]
    vertices[i + 1] = datum[@key2]
  
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
      initialVertices[i + 1] = min2
    
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
    @gl.uniform3f(@uMinimum1, @extents.xmin, @extents.ymin, 0)
    @gl.uniform3f(@uMaximum1, @extents.xmax, @extents.ymax, 1)
    
    # Bind current extents to uMinimum2 and uMaximum2
    @gl.uniform3f(@uMinimum2, min1, min2, 0)
    @gl.uniform3f(@uMaximum2, max1, max2, 1)
    
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
    @gl.uniform3f(@uMinimum1, min1, min2, 0)
    @gl.uniform3f(@uMaximum1, max1, max2, 1)
    
    # Bind previous extents to uMinimum2 and uMaximum2
    @gl.uniform3f(@uMinimum2, @extents.xmin, @extents.ymin, 0)
    @gl.uniform3f(@uMaximum2, @extents.xmax, @extents.ymax, 1)
    
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @dataBuffer2)
    @gl.vertexAttribPointer(@programs.ruse.aVertexPosition2, @dataBuffer2.itemSize, @gl.FLOAT, false, 0, 0)
    
    @switch = 0
  
  # Store computed extents for use when creating axes
  @extents =
    xmin: min1
    xmax: max1
    ymin: min2
    ymax: max2
  
  @drawAxes()
  @drawMode = @gl.POINTS
  @axesCanvas.onmousemove = null
  @animate()