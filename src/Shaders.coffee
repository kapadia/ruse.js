
Shaders =
  
  vertex: [
    "attribute vec3 aPoints1;"
    "attribute vec3 aPoints2;"
    
    "uniform mat4 uMVMatrix;"
    "uniform mat4 uPMatrix;"
    
    "uniform float uTime;"
    "uniform float uSwitch;"
    
    "void main(void) {"
        "gl_PointSize = 1.25;"
        "vec3 vertexPosition = (1.0 - abs(uTime - uSwitch)) * aPoints2 + abs(uTime - uSwitch) * aPoints1;"
        "gl_Position = uPMatrix * uMVMatrix * vec4(vertexPosition, 1.0);"
    "}"
  ].join("\n")
  
  fragment: [
    "precision mediump float;"
  
    "void main(void) {"
      "gl_FragColor = vec4(0.0, 0.4431, 0.8980, 1.0);"
    "}"
  ].join("\n")


@astro.Ruse.Shaders = Shaders
