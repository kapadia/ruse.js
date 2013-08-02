{print} = require 'util'
{spawn} = require 'child_process'

task 'build', 'Build dist/ from src/', ->
  
  # Get parameters from package.json
  pkg = require('./package.json')
  
  # Specify the name of the library
  output = "dist/#{pkg['name']}.js"
  
  # Check that developer has specified a dependency order
  unless pkg['_dependencyOrder']?
    process.stderr.write "ERROR: The dependency order must be specified in package.json\n"
    return
  
  # Concatentate the dependency order
  order = pkg['_dependencyOrder']
  for dep, index in order
    order[index] = "src/#{dep}.coffee"
    
  # Set the flags for coffeescript compilation
  flags = ['-j', output, '-c'].concat order
  
  # Compile to JavaScript
  coffee = spawn 'coffee', flags
  
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0


task 'server', 'Build dist/ from src/', ->
  
  # Get parameters from package.json
  pkg = require('./package.json')
  
  # Specify the name of the library
  output = "dist/#{pkg['name']}"
  
  # Check that developer has specified a dependency order
  unless pkg['_dependencyOrder']?
    process.stderr.write "ERROR: The dependency order must be specified in package.json\n"
    return
    
  # Concatentate the dependency order
  order = pkg['_dependencyOrder']
  for dep, index in order
    order[index] = "src/#{dep}.coffee"
    
  # Set the flags for coffeescript compilation
  flags = ['-w', '-j', output, '-c'].concat order
  
  # Compile to JavaScript
  coffee = spawn 'coffee', flags
  server = spawn 'http-server'
  
  for p in [coffee, server]
    p.stderr.on 'data', (data) ->
      process.stderr.write data.toString()
    p.stdout.on 'data', (data) ->
      print data.toString()