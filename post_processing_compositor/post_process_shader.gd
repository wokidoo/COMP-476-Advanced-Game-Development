@tool
extends CompositorEffect
class_name PostProcessShader

const template_shader: String = """
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Read/write color buffer
layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

// Render buffers
layout(set = 0, binding = 1) uniform sampler2D depth_texture;
layout(set = 0, binding = 2) uniform sampler2D velocity_texture;
layout(set = 0, binding = 3) uniform sampler2D normal_roughness_texture;

// Inspector textures
layout(set = 0, binding = 4) uniform sampler2D tex_a_sampler;
layout(set = 0, binding = 5) uniform sampler2D tex_b_sampler;

layout(push_constant, std430) uniform Params {
    vec2 raster_size;
    float time;
    float pad0; // alignment

    // 8 user-defined sliders:
    float user_slider_0;
    float user_slider_1;
    float user_slider_2;
    float user_slider_3;

    float user_slider_4;
    float user_slider_5;
    float user_slider_6;
    float user_slider_7;
} params;

float bayer4(ivec2 p) {
    // Wrap to 4x4 tile
    int x = p.x & 3;
    int y = p.y & 3;
    int idx = y * 4 + x;
    
    // 4x4 Bayer matrix values in [0, 15]:
    //  0  8  2 10
    // 12  4 14  6
    //  3 11  1  9
    // 15  7 13  5
    int m[16] = int[16](
         0,  8,  2, 10,
        12,  4, 14,  6,
         3, 11,  1,  9,
        15,  7, 13,  5
    );

    // Normalize to 0..1
    return (float(m[idx]) + 0.5) / 16.0;
}

float compute_edge(
    vec2 uv_center,
    vec2 px,
    vec2 uv_min,
    vec2 uv_max,
    float depth_threshold,
    float normal_threshold,
    float edge_falloff
) {
    vec2 uv_l = clamp(uv_center - vec2(px.x, 0.0), uv_min, uv_max);
    vec2 uv_r = clamp(uv_center + vec2(px.x, 0.0), uv_min, uv_max);
    vec2 uv_u = clamp(uv_center - vec2(0.0, px.y), uv_min, uv_max);
    vec2 uv_d = clamp(uv_center + vec2(0.0, px.y), uv_min, uv_max);

    float d_c = texture(depth_texture, uv_center).r;
    float depth_edge =
        max(max(abs(d_c - texture(depth_texture, uv_l).r),
                abs(d_c - texture(depth_texture, uv_r).r)),
            max(abs(d_c - texture(depth_texture, uv_u).r),
                abs(d_c - texture(depth_texture, uv_d).r)));

    float depth_mask = smoothstep(depth_threshold,
                                  depth_threshold + edge_falloff,
                                  depth_edge);

    // decode normals but DO NOT normalize
    vec3 n_c = texture(normal_roughness_texture, uv_center).xyz * 2.0 - 1.0;
    vec3 n_l = texture(normal_roughness_texture, uv_l).xyz * 2.0 - 1.0;
    vec3 n_r = texture(normal_roughness_texture, uv_r).xyz * 2.0 - 1.0;
    vec3 n_u = texture(normal_roughness_texture, uv_u).xyz * 2.0 - 1.0;
    vec3 n_d = texture(normal_roughness_texture, uv_d).xyz * 2.0 - 1.0;

    // normalize-invariant-ish similarity (approx): compare via dot, but rescale by lengths
    // If you want even cheaper, remove the inversesqrt and just use raw dot.
    float inv_c = inversesqrt(max(dot(n_c, n_c), 1e-8));

    float diff_l = 1.0 - clamp(dot(n_c, n_l) * inv_c * inversesqrt(max(dot(n_l, n_l), 1e-8)), 0.0, 1.0);
    float diff_r = 1.0 - clamp(dot(n_c, n_r) * inv_c * inversesqrt(max(dot(n_r, n_r), 1e-8)), 0.0, 1.0);
    float diff_u = 1.0 - clamp(dot(n_c, n_u) * inv_c * inversesqrt(max(dot(n_u, n_u), 1e-8)), 0.0, 1.0);
    float diff_d = 1.0 - clamp(dot(n_c, n_d) * inv_c * inversesqrt(max(dot(n_d, n_d), 1e-8)), 0.0, 1.0);

    float normal_edge = max(max(diff_l, diff_r), max(diff_u, diff_d));

    float normal_mask = smoothstep(normal_threshold,
                                   normal_threshold + edge_falloff,
                                   normal_edge);

    return max(depth_mask, normal_mask);
}


void main() {
    float TIME = params.time;

    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    ivec2 size = ivec2(params.raster_size);

    if (uv.x >= size.x || uv.y >= size.y) {
        return;
    }

    ivec2 PIXEL_COORD = uv;

    vec2 FRAGCOORD = vec2(uv) + vec2(0.5);

    vec2 SCREEN_UV = (vec2(uv) + vec2(0.5)) / params.raster_size;
    vec2 VIEWPORT_SIZE = params.raster_size;
    vec2 VIEWPORT_INV_SIZE = 1.0 / params.raster_size;

    vec4 color = imageLoad(color_image, uv);

    #COMPUTE_CODE

    imageStore(color_image, uv, color);
}
"""

@export var tex_a: Texture2D
@export var tex_b: Texture2D

# User-defined sliders (0..7)
@export var sliders: Array[ShaderSlider] = []

@export_multiline var shader_code: String = "":
	set(value):
		mutex.lock()
		shader_code = value
		shader_is_dirty = true
		mutex.unlock()

var rd: RenderingDevice
var shader: RID
var pipeline: RID

var mutex: Mutex = Mutex.new()
var shader_is_dirty: bool = true

var sampler_clamp: RID   # for depth / velocity / normals
var sampler_repeat: RID  # for tex_a / tex_b (repeat)
var default_tex: Texture2D  # 1x1 white used when tex_a / tex_b are not set

func _init() -> void:
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()

	needs_normal_roughness = true
	needs_motion_vectors = true
	
	if rd:
		# Clamp sampler (for depth / velocity / normals)
		var s_clamp := RDSamplerState.new()
		s_clamp.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		s_clamp.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		s_clamp.mip_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		s_clamp.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		s_clamp.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		s_clamp.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_CLAMP_TO_EDGE
		sampler_clamp = rd.sampler_create(s_clamp)

		# Repeat sampler (for inspector textures)
		var s_repeat := RDSamplerState.new()
		s_repeat.min_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		s_repeat.mag_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		s_repeat.mip_filter = RenderingDevice.SAMPLER_FILTER_NEAREST
		s_repeat.repeat_u = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
		s_repeat.repeat_v = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
		s_repeat.repeat_w = RenderingDevice.SAMPLER_REPEAT_MODE_REPEAT
		sampler_repeat = rd.sampler_create(s_repeat)

	_create_default_texture()

func _create_default_texture() -> void:
	if default_tex:
		return
	var img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	default_tex = ImageTexture.create_from_image(img)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if shader.is_valid():
			rd.free_rid(shader)
		if sampler_clamp.is_valid():
			rd.free_rid(sampler_clamp)
		if sampler_repeat.is_valid():
			rd.free_rid(sampler_repeat)

# --- Shader compilation -------------------------------------------------------

func _check_shader() -> bool:
	if not rd:
		return false

	var new_shader_code := ""

	mutex.lock()
	if shader_is_dirty:
		new_shader_code = shader_code
		shader_is_dirty = false
	mutex.unlock()

	if new_shader_code.is_empty():
		return pipeline.is_valid()

	new_shader_code = template_shader.replace("#COMPUTE_CODE", new_shader_code)

	if shader.is_valid():
		rd.free_rid(shader)
		shader = RID()
		pipeline = RID()

	var shader_source := RDShaderSource.new()
	shader_source.language = RenderingDevice.SHADER_LANGUAGE_GLSL
	shader_source.source_compute = new_shader_code
	var shader_spirv: RDShaderSPIRV = rd.shader_compile_spirv_from_source(shader_source)

	if shader_spirv.compile_error_compute != "":
		push_error(shader_spirv.compile_error_compute)
		push_error("In: " + new_shader_code)
		return false

	shader = rd.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid():
		return false

	pipeline = rd.compute_pipeline_create(shader)
	return pipeline.is_valid()

# --- Render callback ----------------------------------------------------------

func _render_callback(p_effect_callback_type: int, p_render_data) -> void:
	if not (rd and p_effect_callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT and _check_shader()):
		return

	var render_scene_buffers: RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
	if not render_scene_buffers:
		return

	var size: Vector2i = render_scene_buffers.get_internal_size()
	if size.x == 0 and size.y == 0:
		return

	var x_groups := int((size.x - 1) / 8.0) + 1.0
	var y_groups := int((size.y - 1) / 8.0) + 1.0
	var z_groups := 1.0

	# Push constants: raster_size.xy, time, pad0, 8 slider floats
	var push_constant := PackedFloat32Array()

	# raster_size
	push_constant.push_back(size.x)
	push_constant.push_back(size.y)

	# time + padding
	push_constant.push_back(Engine.get_frames_drawn())
	push_constant.push_back(0.0) # pad0

	# 8 slider values
	for i in range(8):
		var v := 0.0
		if i < sliders.size() and sliders[i] != null:
			v = sliders[i].value
		push_constant.push_back(v)

	var view_count := render_scene_buffers.get_view_count()
	for view in range(view_count):
		var color_image: RID = render_scene_buffers.get_color_layer(view)
		var uniforms: Array[RDUniform] = []

		# Binding 0: storage image for the main screen buffer.
		var u_screen := RDUniform.new()
		u_screen.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		u_screen.binding = 0
		u_screen.add_id(color_image)
		uniforms.append(u_screen)

		# Binding 1: depth
		if sampler_clamp.is_valid():
			var depth_tex: RID = render_scene_buffers.get_depth_layer(view)
			if depth_tex.is_valid():
				var u_depth := RDUniform.new()
				u_depth.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				u_depth.binding = 1
				u_depth.add_id(sampler_clamp)
				u_depth.add_id(depth_tex)
				uniforms.append(u_depth)

		# Binding 2: velocity
		if sampler_clamp.is_valid():
			var vel_tex: RID = render_scene_buffers.get_velocity_layer(view)
			if vel_tex.is_valid():
				var u_vel := RDUniform.new()
				u_vel.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				u_vel.binding = 2
				u_vel.add_id(sampler_clamp)
				u_vel.add_id(vel_tex)
				uniforms.append(u_vel)

		# Binding 3: normal + roughness
		if sampler_clamp.is_valid():
			var nrm_tex: RID = render_scene_buffers.get_texture("forward_clustered", "normal_roughness")
			if nrm_tex.is_valid():
				var u_nrm := RDUniform.new()
				u_nrm.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				u_nrm.binding = 3
				u_nrm.add_id(sampler_clamp)
				u_nrm.add_id(nrm_tex)
				uniforms.append(u_nrm)

		if not default_tex:
			_create_default_texture()

		# Binding 4: tex_a (repeat)
		if sampler_repeat.is_valid() and default_tex:
			var tex_a_tex: Texture2D = tex_a if tex_a else default_tex
			var tex_a_rid: RID = RenderingServer.texture_get_rd_texture(tex_a_tex.get_rid())
			if tex_a_rid.is_valid():
				var u_tex_a := RDUniform.new()
				u_tex_a.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				u_tex_a.binding = 4
				u_tex_a.add_id(sampler_repeat)
				u_tex_a.add_id(tex_a_rid)
				uniforms.append(u_tex_a)

		# Binding 5: tex_b (repeat)
		if sampler_repeat.is_valid() and default_tex:
			var tex_b_tex: Texture2D = tex_b if tex_b else default_tex
			var tex_b_rid: RID = RenderingServer.texture_get_rd_texture(tex_b_tex.get_rid())
			if tex_b_rid.is_valid():
				var u_tex_b := RDUniform.new()
				u_tex_b.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
				u_tex_b.binding = 5
				u_tex_b.add_id(sampler_repeat)
				u_tex_b.add_id(tex_b_rid)
				uniforms.append(u_tex_b)

		var uniform_set = UniformSetCacheRD.get_cache(shader, 0, uniforms)

		var compute_list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		rd.compute_list_set_push_constant(
			compute_list,
			push_constant.to_byte_array(),
			push_constant.size() * 4
		)
		rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
		rd.compute_list_end()
