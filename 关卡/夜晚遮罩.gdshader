shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;

// 光照遮罩（多光源版，三种模式共用）
// 槽位：86 = 1 个英雄夜视 + 85 个余烬
// 编码：x,y = 屏幕像素中心；z = 半径像素（<=0 表示空槽）；w = 色板下标（0=英雄白光，1~4=余烬主色）
// 内圈全亮半径固定 0：从圆心开始连续变暗，到半径边缘降为圆外黑度。
// 压暗取最大照度（含英雄白光）；主色按各余烬照度^p 加权混合（p 默认 1=线性），
// 滤镜强度只取余烬自身最大照度，融合不抬高边缘强度；英雄白光只贡献亮度、不贡献颜色。
uniform vec4 dian_guang[86];
uniform vec3 tiao_se[5];
uniform int dian_guang_shu = 0;
uniform float darkness : hint_range(0.0, 1.0) = 0.0;
uniform float tiao_qiang : hint_range(0.0, 1.0) = 0.1;
// 混色权重指数：1=线性照度（默认），越大越偏向最亮光源
uniform float hun_he_zhi_shu : hint_range(1.0, 4.0) = 1.0;
uniform vec4 night_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// 兼容保留：旧的单光源半径参数，主算法不参与
uniform float outer_radius = 180.0;

void fragment() {
	if (dian_guang_shu <= 0) {
		COLOR = vec4(0.0);
	} else {
		float best = 0.0;      // 所有光源（含英雄夜视）最大照度 → 只用于压暗
		float yu_best = 0.0;   // 仅余烬最大照度 → 只用于滤镜强度
		vec3 se_sum = vec3(0.0);
		float quan_sum = 0.0;
		for (int i = 0; i < 86; i++) {
			if (i >= dian_guang_shu) {
				break;
			}
			vec4 g = dian_guang[i];
			if (g.z <= 0.0) {
				continue;
			}
			float ill = 1.0 - smoothstep(0.0, g.z, distance(FRAGCOORD.xy, g.xy));
			// 压暗只取最大照度
			if (ill > best) {
				best = ill;
			}
			// 余烬主色按照度^p 加权混合；英雄白光（w=0）不参与混色
			if (g.w > 0.5 && ill > 0.0) {
				if (ill > yu_best) {
					yu_best = ill;
				}
				float w = (hun_he_zhi_shu == 1.0) ? ill : pow(ill, hun_he_zhi_shu);
				se_sum += tiao_se[int(g.w)] * w;
				quan_sum += w;
			}
		}
		float aD = darkness * (1.0 - best);
		// 强度只由余烬自身最大照度决定：融合不叠加、不被英雄夜视托住
		float aT = tiao_qiang * yu_best;
		vec3 tint = (quan_sum > 0.0) ? (se_sum / quan_sum) : vec3(1.0);
		// 压暗与主色滤镜一帧合成（预乘 alpha）
		COLOR = vec4(tint * aT * (1.0 - aD), aT + aD - aT * aD);
	}
}