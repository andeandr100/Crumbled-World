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
    v_texCoord = uvCoord;
    
    float offset = 1.0 / width;
    
    // Calculate texture coordinates for blurring
    for (int i = 0; i < 7; i++) {
        float sampleOffset = float(i + 1);
        v_blurTexCoords[i] = v_texCoord + vec2(-offset * sampleOffset, 0.0); // Left samples
        v_blurTexCoords[i + 7] = v_texCoord + vec2(offset * sampleOffset, 0.0); // Right samples
    }
}

