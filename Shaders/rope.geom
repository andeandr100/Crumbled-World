#version 330

uniform mat4 projModelViewMat;

in vec4 pos1[];
in vec4 pos2[];
in vec4 rightVec1[];
in vec4 rightVec2[];
in vec4 upVec1[];
in vec4 upVec2[];
in vec4 col[];
uniform vec2 uv1;
uniform vec2 uv2;
uniform vec2 uvOffset;

layout (points) in;
layout (triangle_strip, max_vertices = 10) out;

out vec2 tc;
out vec4 SpriteColor;
out vec3 worldPos0;
out vec3 worldNor0;

void main( void )
{

SpriteColor = col[0];

/////////////////////////////////////////////////////////

tc = uv2;
worldNor0 = normalize(upVec2[0]).xyz;
worldPos0 = (pos2[0] + upVec2[0]).xyz;
gl_Position = projModelViewMat * pos2[0] + projModelViewMat * upVec2[0];
EmitVertex();

tc = uv1;
worldNor0 = normalize(upVec1[0]).xyz;
worldPos0 = (pos1[0] + upVec1[0]).xyz;
gl_Position = projModelViewMat* pos1[0] + projModelViewMat * upVec1[0];
EmitVertex();


/////////////////////////////////////////////////////////
tc = uv2 + uvOffset;
worldNor0 = normalize(rightVec2[0]).xyz;
worldPos0 = (pos2[0] + rightVec2[0]).xyz;
gl_Position = projModelViewMat * pos2[0] + projModelViewMat * rightVec2[0];
EmitVertex();

tc = uv1 + uvOffset;
worldNor0 = normalize(upVec1[0]).xyz;
worldPos0 = (pos1[0] + rightVec1[0]).xyz;
gl_Position = projModelViewMat* pos1[0] + projModelViewMat * rightVec1[0];
EmitVertex();


/////////////////////////////////////////////////////////
tc = uv2 + uvOffset * 2.0;
worldNor0 = normalize(-upVec2[0]).xyz;
worldPos0 = (pos2[0] - upVec2[0]).xyz;
gl_Position = projModelViewMat * pos2[0] - projModelViewMat * upVec2[0];
EmitVertex();

tc = uv1 + uvOffset * 2.0;
worldNor0 = normalize(-upVec1[0]).xyz;
worldPos0 = (pos1[0] - upVec1[0]).xyz;
gl_Position = projModelViewMat * pos1[0] - projModelViewMat * upVec1[0];
EmitVertex();


/////////////////////////////////////////////////////////
tc = uv2 + uvOffset * 3.0;
worldNor0 = normalize(-rightVec2[0]).xyz;
worldPos0 = (pos2[0] - rightVec2[0]).xyz;
gl_Position = projModelViewMat * pos2[0] - projModelViewMat * rightVec2[0];
EmitVertex();

tc = uv1 + uvOffset * 3.0;
worldNor0 = normalize(-rightVec1[0]).xyz;
worldPos0 = (pos1[0] - rightVec1[0]).xyz;
gl_Position = projModelViewMat * pos1[0] - projModelViewMat * rightVec1[0];
EmitVertex();


/////////////////////////////////////////////////////////
tc = uv2 + uvOffset * 4.0;
worldNor0 = normalize( upVec2[0]).xyz;
worldPos0 = (pos2[0] + upVec2[0]).xyz;
gl_Position = projModelViewMat * pos2[0] + projModelViewMat * upVec2[0];
EmitVertex();

tc = uv1 + uvOffset * 4.0;
worldNor0 = normalize(upVec1[0]).xyz;
worldPos0 = (pos1[0] + upVec1[0]).xyz;
gl_Position = projModelViewMat * pos1[0] + projModelViewMat * upVec1[0];
EmitVertex();


EndPrimitive();

}
