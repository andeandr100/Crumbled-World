#version 330
uniform mat4 projModelViewMat, modelMat;
uniform float width;

in vec4 position;
in vec2 uvCoord;

out vec2 v_texCoord;

void main()
{
	gl_Position = projModelViewMat * modelMat * position;
	v_texCoord = uvCoord;
}


