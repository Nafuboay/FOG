shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

// 夜晚遮罩（多光源版）
// 槽位：86 = 1 个英雄夜视 + 85 个余烬
// 编码：x,y = 屏幕像素中心；z = 半径像素（<=0 表示空槽）；w = 色板下标（0=英雄白光，1~4=余烬主色）
// 内圈全亮半径固定 0：从圆心开始连续变暗，到半径边缘降为圆外黑度；禁止边缘暗角与半径封顶。
uniform vec4 dian_guang[86];
uniform vec3 tiao_se[5];
uniform int dian_guang_shu = 0;
uniform float darkness : hint_range(0.0, 1.0) = 1.0;
uniform float tiao_qiang : hint_range(0.0, 1.0) = 0.35;
uniform vec4 night_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// 兼容保留：旧的单光源半径参数，主算法不参与
uniform float outer_radius = 180.0;

void fragment() {
	float best = 0.0;
	int best_w = 0;
	for (int i = 0; i < 86; i++) {
		if (i >= dian_guang_shu) {
			break;
		}
		vec4 g = dian_guang[i];
		if (g.z <= 0.0) {
			continue;
		}
		float ill = 1.0 - smoothstep(0.0, g.z, distance(FRAGCOORD.xy, g.xy));
		// >= 保证同亮度时后面的光源优先：余烬胜英雄、后放者胜先放者
		if (ill >= best) {
			best = ill;
			best_w = int(g.w);
		}
	}
	// 压暗与主色滤镜一帧合成（预乘 alpha）
	float aD = darkness * (1.0 - best);
	float aT = tiao_qiang * best * ((best_w == 0) ? 0.0 : 1.0);
	vec3 tint = tiao_se[best_w];
	COLOR = vec4(night_color.rgb * aT * (1.0 - aD), aT + aD - aT * aD);
}