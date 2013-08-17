
Shaders =
  
  vertex: [
    "attribute vec3 aPoints1;"
    "attribute vec3 aPoints2;"
    
    "uniform mat4 uMVMatrix;"
    "uniform mat4 uPMatrix;"
    
    "uniform vec3 uMinimum;"
    "uniform vec3 uMaximum;"
    
    "uniform float uTime;"
    "uniform float uSwitch;"
    
    "void main(void) {"
        "gl_PointSize = 1.25;"
        
        "vec3 scale = vec3(2.0, 2.0, 0.0);"
        "vec3 offset = vec3(1.0, 1.0, 0.0);"
        "vec3 range = uMaximum - uMinimum;"
        
        "vec3 points1 = scale / range * (aPoints1 - uMinimum) - offset;"
        "vec3 points2 = scale / range * (aPoints2 - uMinimum) - offset;"
        
        "vec3 vertexPosition = (1.0 - abs(uTime - uSwitch)) * points2 + abs(uTime - uSwitch) * points1;"
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
