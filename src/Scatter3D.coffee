
Ruse = @astro.Ruse

Ruse::scatter3D = (data) ->
  console.log 'scatter3D'
  
  # Add perspective when working in three dimensions
  mat4.perspective(@pMatrix, 45.0, @canvas.width / @canvas.height, 0.1, 100.0)
  mat4.translate(@mvMatrix, @mvMatrix, [0.0, 0.0, -4.5])
  
  @gl.useProgram(@programs.three)
  
  # Attributes are peculiar.  Each attribute across all programs *must* be associated with a buffer.
  # Associate with junk data for now.
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
  
  # Proceed to handling the real data
  
  vertices = new Float32Array([
    # Front face
    0.0,  1.0,  0.0,
    -1.0, -1.0,  1.0,
    1.0, -1.0,  1.0,
    
    # Right face
    0.0,  1.0,  0.0,
    1.0, -1.0,  1.0,
    1.0, -1.0, -1.0,
    
    # Back face
    0.0,  1.0,  0.0,
    1.0, -1.0, -1.0,
    -1.0, -1.0, -1.0,
    
    # Left face
    0.0,  1.0,  0.0,
    -1.0, -1.0, -1.0,
    -1.0, -1.0,  1.0
  ])
  
  @gl.bindBuffer(@gl.ARRAY_BUFFER, @threeBuffer)
  @threeBuffer.itemSize = 3
  @threeBuffer.numItems = 12
  
  @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
  @gl.vertexAttribPointer(@programs.three.vertexPositionAttribute, @threeBuffer.itemSize, @gl.FLOAT, false, 0, 0)
  
  @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)
  @_setMatrices(@programs.three)
  @gl.drawArrays(@gl.POINTS, 0, @threeBuffer.numItems)