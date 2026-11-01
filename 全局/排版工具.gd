extends Node
# 排版工具单例：预处理文本，让信息面板 Label 按 CJK 禁则断行
# 用法：排版工具.pai_ban_wen_ben(text) 替换原来直接 label.text = text

const _ZWSP: int = 0x200B  # 零宽空格（Zero Width Space）—— 允许断行，不可见
const _WJ: int = 0x2060    # 零宽不换行空格（Word Joiner）—— 禁止在它附近断行，不可见

# 开口符号：可以出现在行首，但不能被单独留在行尾（必须和后字绑在一起）
# 处理：前插 ZWSP（允许断在它前面，整组可挪到行首）+ 后插 WJ（和后字绑死）
var _KAI_KOU: Array = [
	0x300A,  # 《
	0x3010,  # 【
	0xFF08,  # （
	0x0028,  # (
	0x005B,  # [
]

# 闭口符号/标点：可以留在行尾，但不能跑到行首（必须和前字绑在一起）
# 处理：只前插 WJ（和前字绑死）；后面不用管——后一个字符前的 ZWSP 自然提供断点
var _BI_KOU: Array = [
	0x300B,  # 》
	0x3011,  # 】
	0x300D,  # 」
	0xFF09,  # ）
	0x0029,  # )
	0x005D,  # ]
	0xFF0C,  # ，
	0x3002,  # 。
	0xFF01,  # ！
	0xFF1F,  # ？
	0xFF1B,  # ；
	0xFF1A,  # ：
	0x3001,  # 、
	0x002C,  # ,
	0x002E,  # .
	0x0021,  # !
	0x003F,  # ?
	0x003B,  # ;
	0x003A,  # :
]

# 判断字符是否属于"单词字符"（ASCII 字母 / 撇号）
# 同一个单词内部不插 ZWSP，保证英文单词不被拆散
func _shi_dan_ci_zi_fu(c: int) -> bool:
	return (c >= 0x41 and c <= 0x5A) or \
		   (c >= 0x61 and c <= 0x7A) or \
		   c == 0x27  # ' 撇号，让 don't 这类词不拆开

# 判断普通字符是否需要在它之前插 ZWSP（允许断行）
# 运算符号 + - × / % 不插，让它们自然跟随空格断行（运算表达式不绑死）
func _xu_yao_ZWSP(c: int) -> bool:
	# 硬换行、Tab、各种空白不插
	if c == 0x0A or c == 0x0D or c == 0x09 or c == 0x2028 or c == 0x2029:
		return false
	if c == 0x0020 or c == 0x00A0:
		return false
	# 运算符号不插断点（数字×数字 保持原样）
	if c == 0x002B or c == 0x002D or c == 0x00D7 or c == 0x002F or c == 0x0025:
		return false
	# 其余字符（CJK 字、英文、数字等）：允许在它之前断行
	return true

# 预处理文本：按 CJK 禁则规则插入零宽控制字符
# 输入原始字符串，输出加工后的字符串，直接赋给 label.text（配合 AUTOWRAP_WORD_SMART 使用）
func pai_ban_wen_ben(wen_ben: String) -> String:
	if wen_ben.is_empty():
		return wen_ben
	var jie_guo: String = ""
	var n: int = wen_ben.length()
	for i in n:
		var c: int = wen_ben.unicode_at(i)
		# 硬换行原样保留
		if c == 0x0A or c == 0x0D:
			jie_guo += char(c)
			continue
		if _BI_KOU.has(c):
			# 闭口：前插 WJ，和前字绑死，防跑行首
			jie_guo += char(_WJ)
		elif _KAI_KOU.has(c):
			# 开口：前插 ZWSP，允许断在它前面，可挪到行首
			jie_guo += char(_ZWSP)
		elif _xu_yao_ZWSP(c):
			# 普通字符前插 ZWSP；但同一个英文单词内部（前后都是单词字符）不插，防拆词
			var qian: int = wen_ben.unicode_at(i - 1) if i > 0 else -1
			if not (_shi_dan_ci_zi_fu(c) and _shi_dan_ci_zi_fu(qian)):
				jie_guo += char(_ZWSP)
		# 字符本身
		jie_guo += char(c)
		# 开口：后插 WJ，和后字绑死，防单独留在行尾
		if _KAI_KOU.has(c):
			jie_guo += char(_WJ)
	return jie_guo
