#version 330
uniform mat4 projModelViewMat, modelMat;

layout (location = 0) in vec4 position; 

uniform float time;

out vec2 TextCord;
	
void main()
{
	float timeDist = (time + modelMat[3][0] * 0.1 + modelMat[3][2]*0.2) * 0.75;
	vec2 addVec = vec2( sin(timeDist*0.5 + 0.5*cos(time*0.1)) * position.z*0.02, cos(timeDist) * position.z*0.02 );
	vec4 worldPos = modelMat * position + vec4(addVec.xy, (cos(length(addVec) * 0.2243994) - 1.0) * 6.0, 0.0);

	gl_Position = projModelViewMat * worldPos;
}
