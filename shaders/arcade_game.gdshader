shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_count : hint_range(0.0, 1000.0) = 400.0;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 uv = UV;
	vec4 color = texture(SCREEN_TEXTURE, uv);
	
	// Efecto de líneas de escaneo (Scanlines)
	float scanline = sin(uv.y * scanline_count * 3.14159 * 2.0);
	color.rgb -= scanline * 0.035;
	
	// Viñeta oscura en las esquinas
	vec2 center = uv - 0.5;
	float vignette = dot(center, center);
	color.rgb -= vignette * vignette_intensity;
	
	COLOR = color;
}