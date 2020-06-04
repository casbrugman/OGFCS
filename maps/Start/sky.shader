shader_type spatial;

render_mode cull_disabled, cull_front;

uniform int seed;

vec3 hash(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));

    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float noise(vec3 p) {
	p.y += float(seed);
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	
	return mix(mix(mix(dot(hash(i + vec3(0.0, 0.0, 0.0)), f - vec3(0.0, 0.0, 0.0)),
	                    dot(hash(i + vec3(1.0, 0.0, 0.0)), f - vec3(1.0, 0.0, 0.0)), u.x),
	                mix(dot(hash(i + vec3(0.0, 1.0, 0.0)), f - vec3(0.0, 1.0, 0.0)),
	                    dot(hash(i + vec3(1.0, 1.0, 0.0)), f - vec3(1.0, 1.0, 0.0)), u.x), u.y),
	            mix(mix(dot(hash(i + vec3(0.0, 0.0, 1.0)), f - vec3(0.0, 0.0, 1.0)),
	                    dot(hash(i + vec3(1.0, 0.0, 1.0)), f - vec3(1.0, 0.0, 1.0)), u.x),
	                mix(dot(hash(i + vec3(0.0, 1.0, 1.0)), f - vec3(0.0, 1.0, 1.0)),
	                    dot(hash(i + vec3(1.0, 1.0, 1.0)), f - vec3(1.0, 1.0, 1.0)), u.x), u.y), u.z );
}

void fragment(){
	float theta = UV.y * 3.14159;
	float phi = UV.x * 3.14159 * 2.0;
	vec3 unit = vec3(0.0, 0.0, 0.0);

	unit.x = sin(phi) * sin(theta);
	unit.y = cos(theta) * -1.0;
	unit.z = cos(phi) * sin(theta);
	unit = normalize(unit);

	vec3 color0 = vec3(0f,1f,1f); //light blue
	vec3 color1 = vec3(0f,0f,.3f); //blue
	vec3 color2 = vec3(.8f,0f,.8f); //purple

	float height = -.15f;

	if (unit.y > height){
		EMISSION = mix(color1, color0, (unit.y - height) * .4f); // under
	} else{
		EMISSION = mix(color1, color2, (-unit.y + height) * 1f); // above
	}
	
	//stars
	// layer 1
	float a0 = noise(unit * 400f);
	float result0 = 1f;

	if (a0 < 0.5){
		result0 = 0f;
	}

	//layer 2
	float a2 = noise(unit * 400f);
	float b2 = noise(unit * 5f);

	float c2 = mix(a2, b2, .3f);

	float result2 = 1f;

	if (c2 < 0.37){
		result2 = 0f;
	}
	
	float result = result0 + result2;
	
	if (result >= 1f){
		EMISSION = vec3(5f);
	}
	
	SPECULAR = 0f;
}

