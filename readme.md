ShaderScan - better iteration with shaders

# Features

* reloads shaders when they're saved
* include shaders into other shaders
* handles circular include dependencies
* send uniforms to shaders and ignore unused errors

# Reload

If you call ShaderScan.update from love.update, it will watch for changes to
your shaders and reload them if they've changed. If there are errors,
ShaderScan will report the errors but keep using the previous version of the
shader.


# Better Errors

Tired of getting these errors?

Bad code without any indication which shader it came from:

    Error: Error validating pixel shader code:
    Line 20: ERROR: 'pingpon' : no matching overloaded function found 
    Line 20: ERROR: '' : compilation terminated 
    ERROR: 2 compilation errors.  No code generated.

Sending a uniform that doesn't exist:

    Error: main.lua:42: Shader uniform 'iSinTime' does not exist.
    A common error is to define but not use the variable.


Instead, get errors with file, line number, and the specific line that failed:

    Error: shaderscan.lua:126: Loading 'splitcolor' failed: Error validating pixel shader code:
    example/splitcolor.glsl:20: in 'splitcolor' ERROR: 'pingpon' : no matching overloaded function found
    example/splitcolor.glsl:20: in 'splitcolor' ERROR: '' : compilation terminated
    ERROR: 2 compilation errors.  No code generated.
    File: example/splitcolor.glsl
    Line:
            + overlay * pingpon(iTime / cycle_duration);

Sending a uniform that doesn't exist with ShaderScan.safe_send prints the error
once, but doesn't fail.


# Support `#include`

Did you try to use includes and get these errors:

    Line 5: ERROR: '#include' : required extension not requested: GL_GOOGLE_include_directive
    Line 5: ERROR: '#include' : must be followed by a header name 

Use #include directives and modularize your shader code. All includes are
relative to your project's root (the location of main.lua).


# License

MIT License. See LICENSE.md.
