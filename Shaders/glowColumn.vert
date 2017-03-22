#version 330
uniform mat4 projModelViewMat, modelMat;
uniform float height;


in vec4 position;
in vec2 uvCoord;

out vec2 v_texCoord;
out vec2 v_blurTexCoords[14];

void main()
{
	gl_Position = projModelViewMat * modelMat * position;

	float offset = 1.0/height;
	v_texCoord = uvCoord;
    v_blurTexCoords[ 0] = v_texCoord + vec2(0.0, -offset*7);
    v_blurTexCoords[ 1] = v_texCoord + vec2(0.0, -offset*6);
    v_blurTexCoords[ 2] = v_texCoord + vec2(0.0, -offset*5);
    v_blurTexCoords[ 3] = v_texCoord + vec2(0.0, -offset*4);
    v_blurTexCoords[ 4] = v_texCoord + vec2(0.0, -offset*3);
    v_blurTexCoords[ 5] = v_texCoord + vec2(0.0, -offset*2);
    v_blurTexCoords[ 6] = v_texCoord + vec2(0.0, -offset*1);
    v_blurTexCoords[ 7] = v_texCoord + vec2(0.0,  offset*1);
    v_blurTexCoords[ 8] = v_texCoord + vec2(0.0,  offset*2);
    v_blurTexCoords[ 9] = v_texCoord + vec2(0.0,  offset*3);
    v_blurTexCoords[10] = v_texCoord + vec2(0.0,  offset*4);
    v_blurTexCoords[11] = v_texCoord + vec2(0.0,  offset*5);
    v_blurTexCoords[12] = v_texCoord + vec2(0.0,  offset*6);
    v_blurTexCoords[13] = v_texCoord + vec2(0.0,  offset*7);
}
