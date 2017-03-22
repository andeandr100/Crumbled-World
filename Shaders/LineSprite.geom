#version 150
in vec4 pos[];
in vec2 uvCord[];
in vec2 uvCordMax[];
in vec4 col[];
in vec4 atVec[];
in vec4 rightVec[];

layout (points) in;
layout (triangle_strip, max_vertices = 4) out;

out vec4 posx;
out vec2 tc;
out vec4 SpriteColor;

uniform mat4 projMat;

void main( void )
{

	vec4 up = vec4(0,5,0,0);

	SpriteColor = col[0];
	tc= uvCord[0];
	gl_Position = vec4( pos[0] + atVec[0] - projMat * rightVec[0] );
	EmitVertex();


	tc= vec2( uvCord[0].x, uvCordMax[0].y);
	gl_Position = vec4( pos[0] + atVec[0] + projMat * rightVec[0] );
	EmitVertex();


	tc= vec2(uvCordMax[0].x, uvCord[0].y);
	gl_Position = vec4( pos[0] - atVec[0] - projMat * rightVec[0] );
	EmitVertex();


	tc= uvCordMax[0];
	gl_Position = vec4( pos[0] - atVec[0] + projMat * rightVec[0] );
	EmitVertex();

	EndPrimitive();

}
