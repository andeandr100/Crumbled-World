#version 150
in vec4 position;
in vec4 color;

uniform mat4 projModelViewMat, modelMat;

out vec4 pos;
out vec4 lifeBarValues;
out float value;

void main( void )
{
    // Pass life value (from position.w) and icon/state values (from color) to geometry shader
    value = position.w;
    lifeBarValues = color;

    // Calculate the screen position of the point
    pos = projModelViewMat * modelMat * vec4(position.xyz, 1.0);
    gl_Position = pos;
}
