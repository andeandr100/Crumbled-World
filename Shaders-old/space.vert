#version 150
uniform mat4 projModelViewMat;
in vec4 position;
in vec4 color;
in vec2 uvCoord;

out vec2 TextCord;
out vec4 vertexColor;

uniform vec3 camPos;
void main()
{
	TextCord = uvCoord;
	vertexColor = color;
	gl_Position = projModelViewMat * vec4(position.xyz + camPos, 1.0f);
}
