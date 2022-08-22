#version 150
in vec4 position;
in vec2 uvCoord;
in vec4 color;
in vec3 inVelocity;
in vec4 inTargetColor;
in vec2 inAttribute;


uniform mat4 projModelViewMat, modelMat;
uniform float particleTime;
uniform float portalSize;


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

	float rad = position.x + timeOffset * 6.283185 * position.y;
	pos=projModelViewMat*modelMat*vec4(cos(rad) * portalSize,sin(rad) * portalSize * 1.5,0.0,1.0);
	gl_Position= pos;
}
