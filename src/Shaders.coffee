
Shaders =
  
  vertex: [
    "attribute vec3 aVertexPosition;"
    
    "uniform mat4 uMVMatrix;"
    "uniform mat4 uPMatrix;"
    
    "void main(void) {"
        "gl_PointSize = 1.25;"
        "gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);"
    "}"
  ].join("\n")
  
  fragment: [
    "precision mediump float;"
  
    "void main(void) {"
      "gl_FragColor = vec4(0.0, 0.4431, 0.8980, 1.0);"
    "}"
  ].join("\n")


@astro.Ruse.Shaders = Shaders
