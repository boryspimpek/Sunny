// NOTE: Shader automatically converted from Godot Engine 4.6.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);
varying vec3 uv1_triplanar_pos;

uniform float uv1_blend_sharpness : hint_range(0.0, 150.0, 0.001);
varying vec3 uv1_power_normal;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

// --- DOWANE PARAMETRY EFEKTU PULSOWANIA LAWY ---
uniform float pulse_speed : hint_range(0.0, 10.0, 0.1) = 3.0;        // Prędkość pulsowania
uniform float emission_energy : hint_range(0.0, 20.0, 0.1) = 3.0;    // Bazowa siła świecenia lawy
uniform float pulse_strength : hint_range(0.0, 5.0, 0.1) = 1.0;      // Jak mocno ma pulsować
uniform float lava_threshold : hint_range(0.0, 1.0, 0.01) = 0.2;     // Odcięcie ciemnej skały (progowanie)

// --- NOWE PARAMETRY DO ZMIANY KOLORU ---
// Kolor gdy lawa jest najciemniejsza (np. ciemny, nasycony pomarańcz)
uniform vec4 color_lava_cool : source_color = vec4(0.6, 0.1, 0.0, 1.0); 
// Kolor gdy lawa jest najjaśniejsza (np. jaskrawy żółto-pomarańczowy)
uniform vec4 color_lava_hot : source_color = vec4(1.0, 0.8, 0.3, 1.0);

// Parametr wydłużający stan pomarańczowy (chłodnej lawy). >1 = pomarańczowy trwa dłużej, <1 = jasny żółto-pomarańczowy trwa dłużej
uniform float orange_hold : hint_range(0.1, 10.0, 0.1) = 3.0;

// Przesunięcie fazowe dla każdej instancji (ustawiane np. skryptem na każdej skale)
instance uniform float phase_offset : hint_range(0.0, 6.2832, 0.01) = 0.0;


void vertex() {
	vec3 normal = NORMAL;

	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);

	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);

	// UV1 Triplanar: Enabled
	uv1_power_normal = pow(abs(NORMAL), vec3(uv1_blend_sharpness));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_power_normal /= dot(uv1_power_normal, vec3(1.0));
	uv1_triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

void fragment() {
	vec4 albedo_tex = triplanar_texture(texture_albedo, uv1_power_normal, uv1_triplanar_pos);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(triplanar_texture(texture_metallic, uv1_power_normal, uv1_triplanar_pos), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(triplanar_texture(texture_roughness, uv1_power_normal, uv1_triplanar_pos), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

// --- NOWA LOGIKA ŚWIECENIA I ZMIANY KOLORU LAWY ---
	
	// 1. Wyliczenie jasności piksela z pobranej wcześniej tekstury albedo
	float brightness = dot(albedo_tex.rgb, vec3(0.299, 0.587, 0.114));
	
	// 2. Maska: oddzielenie jasnej lawy od ciemnej skały
	float lava_mask = smoothstep(lava_threshold, lava_threshold + 0.2, brightness);
	
	// 3. Płynna fala sinusowa odpowiadająca za pulsowanie (0.0 do 1.0)
	// Używamy jej do dwóch rzeczy: siły świecenia ORAZ koloru.
	float pulse = (sin(TIME * pulse_speed + phase_offset) + 1.0) * 0.5;
	
	// --- NOWOŚĆ: Wyliczenie dynamicznego koloru lawy ---
	// Płynnie mieszamy kolor 'cool' z 'hot' na podstawie wartości pulsu.
	// Wartość pulse_strength wpływa na to, jak bardzo zbliżamy się do koloru 'hot'.
	float pulse_curve = pow(pulse, orange_hold);
	vec3 dynamic_lava_color = mix(color_lava_cool.rgb, color_lava_hot.rgb, pulse_curve * min(1.0, pulse_strength));
	
	// 4. Przypisanie emisji (świecenia).
	// Teraz używamy naszego nowego 'dynamic_lava_color' zamiast ALBEDO.
	EMISSION = dynamic_lava_color * lava_mask * emission_energy;
	
	// OPCJONALNIE: Jeśli chcesz, aby fizyczny kolor skały (ALBEDO) też się zmieniał,
	// odkomentuj poniższą linię. Dzięki temu lawa będzie 'stygła' też na samej teksturze.
	// ALBEDO = mix(ALBEDO, dynamic_lava_color, lava_mask * 0.5); // 0.5 to siła przebarwienia
	}