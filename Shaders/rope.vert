#version 330
in vec3 inPos1;
in vec3 inPos2;
in vec3 inAt1;
in vec3 inAt2;
in vec4 color;

uniform mat4 projModelViewMat;
out vec4 pos1;
out vec4 pos2;
out vec4 rightVec1;
out vec4 rightVec2;
out vec4 upVec1;
out vec4 upVec2;
out vec4 col;

void main( void )
{
	pos1 = vec4(inPos1,1.0);
	pos2 = vec4(inPos2,1.0);

	vec3	tmpRightVec1 = normalize(cross(vec3(0.7, 0.7, 0.0), inAt1));
	vec3	tmpRightVec2 = normalize(cross(vec3(0.7, 0.7, 0.0), inAt2));

	rightVec1 = vec4(tmpRightVec1 * 0.05,0.0);
	rightVec2 = vec4(tmpRightVec2 * 0.05,0.0);

	upVec1 = vec4(normalize(cross(tmpRightVec1, inAt1)) * 0.05,0.0);
	upVec2 = vec4(normalize(cross(tmpRightVec2, inAt2)) * 0.05,0.0);

	col = color;

	gl_Position = projModelViewMat * pos1;
	
}
