#version 150
in vec4 pos[];
in float size[];
in vec2 uvCord[];
in vec2 uvCordAdd[];
in vec4 col[];
in vec4 targetColor[];
in float timeOffset[];


layout (points) in;
layout (triangle_strip, max_vertices = 8) out;

out vec2 tc;
out vec4 SpriteColor;

uniform mat4 projMat;
uniform mat4 modelMat;
uniform mat4 projModelViewMat;

void main( void )
{

	float s = size[0];
	float sx = s * ( uvCordAdd[0].x / uvCordAdd[0].y );

	SpriteColor = (1 - timeOffset[0]) * col[0] + timeOffset[0] * targetColor[0];
	tc= uvCord[0];
	gl_Position = projModelViewMat * modelMat * (pos[0].xyzw + vec4(0.0,-sx, s,0.0));
	EmitVertex();


	tc= uvCord[0] + vec2(0.0,uvCordAdd[0].y);
	gl_Position = projModelViewMat * modelMat *(pos[0].xyzw + vec4(0.0,-sx,-s,0.0));
	EmitVertex();


	tc= uvCord[0] + vec2(uvCordAdd[0].x,0.0);
	gl_Position = projModelViewMat * modelMat *(pos[0].xyzw + vec4(0.0,sx,s,0.0));
	EmitVertex();


	tc= uvCord[0] + uvCordAdd[0];
	gl_Position = projModelViewMat * modelMat *(pos[0].xyzw + vec4(0.0,sx,-s,0.0));
	EmitVertex();

	EndPrimitive();



	tc= uvCord[0];
	gl_Position = projModelViewMat * modelMat * (pos[0].xyzw + vec4(s,-sx, 0,0.0));
	EmitVertex();


	tc= uvCord[0] + vec2(0.0,uvCordAdd[0].y);
	gl_Position = projModelViewMat * modelMat *(pos[0].xyzw + vec4(-s,-sx,0,0.0));
	EmitVertex();


	tc= uvCord[0] + vec2(uvCordAdd[0].x,0.0);
	gl_Position = projModelViewMat * modelMat *(pos[0].xyzw + vec4(s,sx,0,0.0));
	EmitVertex();


	tc= uvCord[0] + uvCordAdd[0];
	gl_Position = projModelViewMat * modelMat *(pos[0].xyzw + vec4(-s,sx,0,0.0));
	EmitVertex();

	EndPrimitive();

}
