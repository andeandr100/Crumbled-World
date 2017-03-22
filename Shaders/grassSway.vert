#version 330
uniform mat4 projModelViewMat, modelMat;
uniform float time;

layout (location = 0) in vec4 position; 
layout (location = 1) in vec3 normal; 
layout (location = 2) in vec2 uvCoord; 
layout (location = 4) in vec4 color;

out vec2 textCoord;
out vec3 worldPos0;
out vec4 vertexColor;
out vec3 worldNormal;


void main()
{
	//Position
	vec4 worldPos = modelMat * vec4( position.xyz, 1.0 );
	float timeDist = (time + modelMat[3][0] * 0.1 + modelMat[3][2]*0.2) * 0.75;
	vec2 addVec = vec2( sin(timeDist*0.5 + 0.5*cos(time*0.1)) * position.w*0.075 , cos(timeDist) * position.w*0.075 );
	worldPos.x += addVec.x;
	worldPos.z += addVec.y;
	worldPos.y -= (1.0 - sin( 1.570796 + ( length( addVec ) / 7 ) * 1.570796 )) * 6.0;

	//color
	vertexColor = color;

	//Normal
	worldNormal = (modelMat * vec4(normal,0)).xyz;

	textCoord = uvCoord;
    worldPos0 = worldPos.xyz;
	gl_Position = projModelViewMat * worldPos;

}
