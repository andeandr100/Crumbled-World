#version 150
uniform mat4 projModelViewMat, modelMat;
uniform vec3 camUpVec, camRightVec, camAtVec;
uniform vec2 offset;

in vec4 position;
in vec2 uvCoord;
in vec4 color;

out vec2 TextCord;
out vec4 VertexColor;

void main()
{
	VertexColor = color;
	TextCord = uvCoord;
	gl_Position = projModelViewMat * modelMat * vec4((offset.y+position.y) * camUpVec + (offset.x+position.z) * camRightVec + position.x * camAtVec, 1.0) ;
}
