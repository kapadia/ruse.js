
Ruse = @astro.Ruse

Ruse::scatter3D = (data) ->
  console.log 'scatter3D'
  
  # Add perspective when working in three dimensions
  mat4.perspective(@pMatrix, 45.0, @canvas.width / @canvas.height, 0.1, 100.0)
  mat4.translate(@mvMatrix, @mvMatrix, [0.0, 0.0, -6.0])
  
  # An older version of glMatrix give this for the perspective matrix.  It's not the same as the latest.
  # NOTE: This matrix is working for another demo.
  @pMatrix = new Float32Array([1.2071068286895752, 0, 0, 0, 0, 2.4142136573791504, 0, 0, 0, 0, -1.0020020008087158, -1, 0, 0, -0.20020020008087158, 0])
  
  @gl.useProgram(@programs.ruse)
  
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
  
  # Attributes are peculiar.  Each attribute across all programs *must* be associated with a buffer.
  # Associate with junk data for now.
  @gl.bindBuffer(@gl.ARRAY_BUFFER, @state1Buffer)
  @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
  @state1Buffer.itemSize = 3
  @state1Buffer.numItems = 12
  @gl.vertexAttribPointer(@programs.ruse.points1Attribute, @state1Buffer.itemSize, @gl.FLOAT, false, 0, 0)
  
  @gl.bindBuffer(@gl.ARRAY_BUFFER, @state2Buffer)
  @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
  @state2Buffer.itemSize = 3
  @state2Buffer.numItems = 12
  @gl.vertexAttribPointer(@programs.ruse.points2Attribute, @state2Buffer.itemSize, @gl.FLOAT, false, 0, 0)
  
  # Proceed to handling the real data
  @gl.useProgram(@programs.three)
  @gl.bindBuffer(@gl.ARRAY_BUFFER, @threeBuffer)
  @threeBuffer.itemSize = 3
  @threeBuffer.numItems = 12
  
  @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
  @gl.vertexAttribPointer(@programs.three.vertexPositionAttribute, @threeBuffer.itemSize, @gl.FLOAT, false, 0, 0)
  
  @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)
  @_setMatrices(@programs.three)
  @gl.drawArrays(@gl.POINTS, 0, @threeBuffer.numItems)
  console.log 'done'
  