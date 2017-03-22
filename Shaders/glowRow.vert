#version 330
uniform mat4 projModelViewMat, modelMat;
uniform float width;

in vec4 position;
in vec2 uvCoord;

out vec2 v_texCoord;
out vec2 v_blurTexCoords[14];

void main()
{
	gl_Position = projModelViewMat * modelMat * position;

	
	float offset = 1.0/width;
	v_texCoord = uvCoord;
    v_blurTexCoords[ 0] = v_texCoord + vec2(-offset*7, 0.0);
    v_blurTexCoords[ 1] = v_texCoord + vec2(-offset*6, 0.0);
    v_blurTexCoords[ 2] = v_texCoord + vec2(-offset*5, 0.0);
    v_blurTexCoords[ 3] = v_texCoord + vec2(-offset*4, 0.0);
    v_blurTexCoords[ 4] = v_texCoord + vec2(-offset*3, 0.0);
    v_blurTexCoords[ 5] = v_texCoord + vec2(-offset*2, 0.0);
    v_blurTexCoords[ 6] = v_texCoord + vec2(-offset*1, 0.0);
    v_blurTexCoords[ 7] = v_texCoord + vec2( offset*1, 0.0);
    v_blurTexCoords[ 8] = v_texCoord + vec2( offset*2, 0.0);
    v_blurTexCoords[ 9] = v_texCoord + vec2( offset*3, 0.0);
    v_blurTexCoords[10] = v_texCoord + vec2( offset*4, 0.0);
    v_blurTexCoords[11] = v_texCoord + vec2( offset*5, 0.0);
    v_blurTexCoords[12] = v_texCoord + vec2( offset*6, 0.0);
    v_blurTexCoords[13] = v_texCoord + vec2( offset*7, 0.0);
}


