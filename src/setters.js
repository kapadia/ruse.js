
ruse.prototype.setColor = function(r, g, b, a) {
  this.gl.useProgram(this.programs.ruse);
  this.gl.uniform4f(this.uColor, r, g, b, a);
  
  this.draw();
  
  if (this.state === "scatter2D") {
    this.drawAxes();
  }
  if (this.state === "scatter3D") {
    this.drawAxes3d();
  }
}