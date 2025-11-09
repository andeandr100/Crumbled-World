#version 330 core
precision mediump float;

uniform sampler2D diffuseMap;

in vec2 v_texCoord;
in vec2 v_blurTexCoords[14];

out vec4 FragColor;

const float weights[8] = float[](
    0.159576912161,
    0.147308056121,
    0.115876621105,
    0.0776744219933,
    0.0443683338718,
    0.0215963866053,
    0.00895781211794,
    0.0044299121055113265
);

void main()
{
    // Central sample
    FragColor = texture(diffuseMap, v_texCoord) * weights[0];

    // Samples to the left and right
    for (int i = 0; i < 7; i++) {
        FragColor += texture(diffuseMap, v_blurTexCoords[i]) * weights[i + 1];
        FragColor += texture(diffuseMap, v_blurTexCoords[i + 7]) * weights[i + 1];
    }
}




