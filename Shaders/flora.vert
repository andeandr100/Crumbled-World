#version 150
uniform mat4 projModelViewMat, modelMat;
in vec3 position;
in float scale;
in float height;
in vec2 uvCoord;
in vec3 color;
uniform vec3 camRightVec;
uniform vec3 camUpVec;
uniform vec3 camAtVec;

uniform vec3 camPos;
uniform int numPointLight;
uniform float time;
uniform vec4 pointLightPos[6];

uniform mat4 lighProjCamView;
smooth out vec4 lightSpace_pos;

uniform vec3 lightDir;
out vec2 TextCord;
out vec3 lDir;

out vec3 outColor;
out vec3 outNormal;
out vec3 outTagent;
out vec3 outBinormal;
out vec3 outEye;

out vec4 outPLightDir[6];
	
void main()
{
	outColor = color;

	outNormal	= -camAtVec;
	outTagent	= camRightVec;
	outBinormal = vec3( 0.0, 1.0, 0.0 );

	TextCord = uvCoord;

	vec4 worldPos = vec4( position, 1.0 ) + vec4( camRightVec * scale + camUpVec*height, 0.0 );

	worldPos.x = worldPos.x + sin(height*0.7) * sin( time + sin( worldPos.x * 1.5 ) ) * 0.1;
	worldPos.z = worldPos.z + sin(height*0.7) * sin( time + sin( worldPos.z * 1.5 ) ) * 0.1;

	worldPos = modelMat * worldPos;

	lightSpace_pos = lighProjCamView * vec4( worldPos.xyz, 1.0 );

	gl_Position = projModelViewMat * worldPos;

	outEye = camPos - worldPos.xyz;
	lDir = lightDir;


	
	for(int i=0; i<numPointLight; i++){
		float radius = pointLightPos[i].w;
		vec3 lightPos = pointLightPos[i].xyz - worldPos.xyz;
		vec4 MylightDir = vec4( lightPos, radius);
		outPLightDir[i] = MylightDir;
	}
}
