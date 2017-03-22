#version 150
uniform mat4 projModelViewMat;
uniform vec3 camPos;
uniform vec3 lightDir;
uniform int numPointLight;
uniform vec4 pointLightPos[16];

in vec3 position;
in vec3 normal;
in vec3 color;
in vec4 inColor1;
in vec3 inColor2;
in vec3 inTagent;

uniform mat4 lighProjCamView;
smooth out vec4 lightSpace_pos;

out vec2 outTextCord;
out vec3 outNormal;
out vec3 outTagent;
out vec3 outBinormal;
out vec4 outColor;
out vec4 outColor1;
out vec3 outColor2;
out vec3 outEye;
out vec3 outlightDir;
out vec4 outPLightDir[16];
void main()
{
	for(int i=0; i<numPointLight; i++){
		float radius = pointLightPos[i].w;
		vec3 lightPos = pointLightPos[i].xyz - position;
		vec4 MylightDir = vec4( lightPos, radius);
		outPLightDir[i] = MylightDir;
	}
	outlightDir = -lightDir;
	outEye = camPos - position;
	outNormal = normal;

	lightSpace_pos = lighProjCamView * vec4( position + normal*0.1f, 1.0 );

	outBinormal = normalize( cross(normal ,vec3(1.0,0.0,0.0) ) );
	outTagent = normalize( cross(outBinormal ,normal ) );
	outTextCord = vec2( position.x * 0.25, position.z * 0.25 );
	outColor = vec4(color, 1.0);
	outColor1 = inColor1;
	outColor2 = inColor2;
	gl_Position = projModelViewMat * vec4( position, 1.0 ) ;
}
