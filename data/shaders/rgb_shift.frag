// Based on a shader by ME!
// YES I FINALLY WROTE SHADERS ON MY OWN LOLOL

#pragma header

uniform float amount;

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec3 col = vec3(1.0);

    col.r = texture(bitmap, uv + amount);
    col.g = texture(bitmap, uv);
    col.b = texture(bitmap, uv - amount);

    gl_FragColor = vec4(col, 1.0);
}