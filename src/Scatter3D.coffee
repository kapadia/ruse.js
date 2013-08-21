
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
  console.log 'scatter3D'
  
  # Add perspective when working in three dimensions
  mat4.perspective(@pMatrix, 45.0, @canvas.width / @canvas.height, 0.1, 100.0)
  mat4.translate(@mvMatrix, @mvMatrix, [0.0, 0.0, -4.5])
  
  @gl.useProgram(@programs.three)
  @spoofAttributes()
  
  # Proceed to handling the real data
  
  # Compute margin that incorporates spaces needed for axes labels
  margin = @getMargin()
  vertexSize = 3
  
  nVertices = data.length
  vertices = new Float32Array(vertexSize * nVertices)
  
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
  
  # Store computed extents for use when creating axes
  @extents =
    xmin: min1
    xmax: max1
    ymin: min2
    ymax: max2
    zmin: min3
    zmax: max3
  
  @gl.uniform3f(@uMinimum, min1, min2, min3)
  @gl.uniform3f(@uMaximum, max1, max2, max3)
  
  range1 = max1 - min1
  range2 = max2 - min2
  range3 = max3 - min3
  
  for datum, index in data
    i = vertexSize * index
    
    vertices[i] = datum[@key1]
    vertices[i + 1] = datum[@key2]
    vertices[i + 2] = datum[@key3]
  
  @gl.bindBuffer(@gl.ARRAY_BUFFER, @threeBuffer)
  @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
  
  @threeBuffer.itemSize = vertexSize
  @threeBuffer.numItems = nVertices
  
  @gl.vertexAttribPointer(@programs.three.vertexPositionAttribute, @threeBuffer.itemSize, @gl.FLOAT, false, 0, 0)
  @_setupMouseControls()
  @draw3d()

Ruse::draw3d = ->
  mat4.identity(@mvMatrix)
  mat4.translate(@mvMatrix, @mvMatrix, [0.0, 0.0, -4.5])
  mat4.multiply(@mvMatrix, @mvMatrix, @rotationMatrix)
  
  @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)
  @_setMatrices(@programs.three)
  @gl.drawArrays(@gl.POINTS, 0, @threeBuffer.numItems)
  