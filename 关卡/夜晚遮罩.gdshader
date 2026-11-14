shader_type canvas_item;
render_mode unshaded;

// 夜晚遮罩：以英雄所在格中心为圆心，圆心向外逐渐加深黑色，
// 到 outer_radius 处达到 darkness 指定的黑度，圆外保持同一黑度。
uniform vec2 center = vec2(640.0, 360.0);
uniform float outer_radius = 180.0;
uniform float darkness : hint_range(0.0, 1.0) = 1;
uniform vec4 night_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	float d = distance(FRAGCOORD.xy, center);
	// 内半径 0：圆心全亮，向外 smoothstep 渐变，半径外保持最大黑度
	float t = smoothstep(0.0, max(outer_radius, 1.0), d);
	COLOR = vec4(night_color.rgb, t * darkness);
}