
ruse.shaders = {
  vertex: [
    "attribute vec3 aVertexPosition1;",
    "attribute vec3 aVertexPosition2;",
    
    "uniform mat4 uMVMatrix;",
    "uniform mat4 uPMatrix;",
    
    "uniform float uMargin;",
    "uniform float uZComponent;",
    
    "uniform vec3 uMinimum1;",
    "uniform vec3 uMaximum1;",
    
    "uniform vec3 uMinimum2;",
    "uniform vec3 uMaximum2;",
    
    "uniform float uTime;",
    
    "void main(void) {",
      "gl_PointSize = 1.25;",
      
      "float scaleComponent = 2.0 * (1.0 - uMargin);",
      "float offsetComponent = (uMargin - 1.0);",
      
      "vec3 scale = vec3(scaleComponent, scaleComponent, uZComponent * scaleComponent);",
      "vec3 offset = vec3(offsetComponent, offsetComponent, uZComponent * offsetComponent);",
      
      "vec3 range1 = uMaximum1 - uMinimum1;",
      "vec3 range2 = uMaximum2 - uMinimum2;",
      
      "vec3 vertexPosition1 = scale / range1 * (aVertexPosition1 - uMinimum1) + offset;",
      "vec3 vertexPosition2 = scale / range2 * (aVertexPosition2 - uMinimum2) + offset;",
      
      "vec3 vertexPosition = (1.0 - uTime) * vertexPosition1 + uTime * vertexPosition2;",
      "gl_Position = uPMatrix * uMVMatrix * vec4(vertexPosition, 1.0);",
    "}"
    ].join("\n"),
  fragment: [
    "precision mediump float;",
    
    "uniform vec4 uColor;",
    
    "void main(void) {",
      "gl_FragColor = uColor;",
    "}"
  ].join("\n"),
  axesVertex: [
    "attribute vec3 aVertexPosition1;",
    "attribute vec3 aVertexPosition2;",
    
    "uniform mat4 uMVMatrix;",
    "uniform mat4 uPMatrix;",
    
    "void main(void) {",
      "vec3 vertexPosition = aVertexPosition2;",
      "gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition1, 1.0);",
    "}"
    ].join("\n"),
  axesFragment: [
    "precision mediump float;",
    
    "void main(void) {",
      "gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);",
    "}"
  ].join("\n")
}
