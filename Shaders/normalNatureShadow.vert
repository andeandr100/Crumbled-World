#version 330
uniform mat4 projModelViewMat, modelMat;

layout (location = 0) in vec4 position; 
layout (location = 2) in vec2 uvCoord; 
//layout (location = 7) in mat4 modelMatrix; 

uniform float time;

out vec2 TextCord;
	
void main()
{
	TextCord = uvCoord;
	vec4 worldPos = modelMat * position;

	float timeDist = (time + modelMat[3][0] * 0.1 + modelMat[3][2]*0.2) * 0.75;
	vec2 addVec = vec2( sin(timeDist*0.5 + 0.5*cos(time*0.1)) * position.z*0.02, cos(timeDist) * position.z*0.02 );
	worldPos.x += addVec.x;
	worldPos.z += addVec.y;
	worldPos.y -= (1.0 - sin( 1.570796 + ( length( addVec ) / 7 ) * 1.570796 )) * 6.0;

	gl_Position = projModelViewMat * worldPos;
}
