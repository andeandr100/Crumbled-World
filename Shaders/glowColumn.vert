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
    v_texCoord = uvCoord;

    float offset = 1.0 / height;

    // Calculate texture coordinates for blurring
    for (int i = 1; i <= 7; i++) {
        float sampleOffset = float(i);
        // Indices 0-6 are for samples above the current fragment
        v_blurTexCoords[7 - i] = v_texCoord + vec2(0.0, -offset * sampleOffset);
        // Indices 7-13 are for samples below the current fragment
        v_blurTexCoords[6 + i] = v_texCoord + vec2(0.0,  offset * sampleOffset);
    }
}
