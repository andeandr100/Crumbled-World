#version 150
in vec3 Pos1[];
in vec3 Pos2[];

uniform mat4 projModelViewMat;

layout (points) in;
layout (triangle_strip, max_vertices = 24) out;

out vec3 color;
out vec3 worldPos0;
out vec3 worldNor0;

void main( void )
{

	vec3 p1 = Pos1[0];
	vec3 p2 = Pos2[0];

	
	vec3 at = normalize(p2 - p1);
	vec3 up = vec3(0,1,0);
	vec3 right = normalize(cross(at.xyz, up));

	up *= 0.07;
	right *= 0.07;

	//top
	color = vec3(0, 0.8, 0.0);
	worldNor0 = vec3(0,1,0);

	worldPos0 = p1 + up - right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p1 + up + right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 + up - right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 + up + right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();
	EndPrimitive();


	//bottom
	color = vec3(0, 0.3, 0.0);
	worldNor0 = vec3(0,-1,0);

	worldPos0 = p1 - up + right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p1 - up - right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 - up + right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 - up - right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();
	EndPrimitive();

	//left
	color = vec3(0, 0.6, 0.0);
	worldNor0 = -right;

	worldPos0 = p1 - right - up;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p1 - right + up;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 - right - up;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 - right + up;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();
	EndPrimitive();

	//right
	color = vec3(0, 0.6, 0.0);
	worldNor0 = right;

	worldPos0 = p1 + right + up;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p1 + right - up;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 + right + up;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 + right - up;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();
	EndPrimitive();


	//back
	color = vec3(0, 0.7, 0.0);
	worldNor0 = -at;

	worldPos0 = p1 - up - right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p1 - up + right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p1 + up - right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p1 + up + right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();
	EndPrimitive();


	//front
	color = vec3(0, 0.7, 0.0);
	worldNor0 = at;

	worldPos0 = p2 + up - right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 + up + right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 - up - right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();

	worldPos0 = p2 - up + right;
	gl_Position = projModelViewMat * vec4(worldPos0,1);
	EmitVertex();
	EndPrimitive();

}
