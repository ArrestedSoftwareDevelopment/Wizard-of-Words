shader_type canvas_item;

void fragment() {
	vec4 sample = texture(TEXTURE, UV);
	float brightest = max(sample.r, max(sample.g, sample.b));
	float darkest = min(sample.r, min(sample.g, sample.b));
	float chroma = brightest - darkest;
	float neutral = 1.0 - smoothstep(0.025, 0.12, chroma);
	float pale = smoothstep(0.72, 0.94, brightest);
	float background = neutral * pale;
	COLOR = vec4(sample.rgb, sample.a * (1.0 - background));
}
