#version 150
in vec4 pos[];
in float size[];
in vec2 uvCord[];
in vec4 col[];
in vec4 targetColor[];
in float timeOffset[];
in float sizeGrowth[];


layout (points) in;
layout (triangle_strip, max_vertices = 4) out;

out vec2 tc;
out vec4 SpriteColor;

uniform mat4 projMat;

void main( void )
{
	

	float s = size[0] + sizeGrowth[0] * timeOffset[0];

	SpriteColor = (1 - timeOffset[0]) * col[0] + timeOffset[0] * targetColor[0];
	tc= uvCord[0];
	gl_Position = pos[0].xyzw + projMat * vec4(s,s,0.0,0.0);
	EmitVertex();


	tc= uvCord[0] + vec2(0.0,0.125);
	gl_Position = pos[0].xyzw + projMat * vec4(s,-s,0.0,0.0);
	EmitVertex();


	tc= uvCord[0] + vec2(0.125,0.0);
	gl_Position = pos[0].xyzw + projMat * vec4(-s,s,0.0,0.0);
	EmitVertex();


	tc= uvCord[0] + vec2(0.125,0.125);
	gl_Position = pos[0].xyzw + projMat * vec4(-s,-s,0.0,0.0);
	EmitVertex();

	EndPrimitive();

}
