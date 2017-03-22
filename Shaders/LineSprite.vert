#version 150
in vec4 position;
in vec2 uvCoord;
in vec2 inTextCordMax;
in vec4 color;
in vec3 inAtVec;
in float width;

uniform mat4 projModelViewMat, modelMat;

out vec4 pos;
out vec2 uvCord;
out vec2 uvCordMax;
out vec4 col;
out vec4 atVec;
out vec4 rightVec;

void main( void )
{
	col = color;
	uvCord = uvCoord;
	uvCordMax = inTextCordMax;
	pos= projModelViewMat*modelMat*vec4(position.xyz,1.0);
	atVec = projModelViewMat *modelMat* vec4(inAtVec, 0.0);

	rightVec = vec4(cross(normalize(vec3(atVec.x, atVec.y, 0)), vec3(0,0,01)), 0) * width;


	gl_Position = pos;
	
}
