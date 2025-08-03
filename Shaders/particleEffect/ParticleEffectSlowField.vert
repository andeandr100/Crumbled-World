#version 150
in vec4 position;
in vec2 uvCoord;
in vec4 color;
in vec3 inVelocity;
in vec4 inTargetColor;
in vec2 inAttribute;


uniform mat4 modelMat;
uniform float particleTime;


out vec4 pos;
out float size;
out vec2 uvCord;
out vec4 col;
out vec4 targetColor;
out float timeOffset;
out float sizeGrowth;

void main( void )
{
	

	col = color;
	uvCord = uvCoord;
	size = position.w;
	targetColor = inTargetColor;
	timeOffset = inAttribute.x + particleTime - floor(inAttribute.x + particleTime);
	sizeGrowth = inAttribute.y;

	vec3 localPos = position.xyz + inVelocity * timeOffset;

	pos=modelMat * vec4(localPos,1.0);
	gl_Position= pos;
}
