shader_type canvas_item;

// ----------------- 外部控制参数 -----------------

// 六层颜色的分界点 (5个 Uniforms)。这些是相对于整个进度条高度 (0.0 到 1.0) 的累积比例。
// 默认值用于编辑器预览，实际由 GDScript 设置
uniform float break_1 = 0.1667;
uniform float break_2 = 0.3334;
uniform float break_3 = 0.5;
uniform float break_4 = 0.6667;
uniform float break_5 = 0.8334;

// 六层颜色 (从上到下: 银、橙、绿、黄、蓝、红)
uniform vec4 color_1 : source_color = vec4(0.75, 0.75, 0.75, 1.0); // 银色 (最上层)
uniform vec4 color_2 : source_color = vec4(1.0, 0.5, 0.0, 1.0);     // 橙色
uniform vec4 color_3 : source_color = vec4(0.0, 0.7, 0.0, 1.0);     // 绿色
uniform vec4 color_4 : source_color = vec4(1.0, 1.0, 0.0, 1.0);     // 黄色
uniform vec4 color_5 : source_color = vec4(0.0, 0.0, 1.0, 1.0);     // 蓝色
uniform vec4 color_6 : source_color = vec4(1.0, 0.0, 0.0, 1.0);     // 红色 (最下层)


void fragment() {
    // UV.y 垂直坐标：顶部 0.0, 底部 1.0
    
    // 进度条始终 100% 填满，因此所有像素都参与分层判断。

    // 确定颜色分层：从上到下（UV.y 递增）检查 break point
    if (UV.y < break_1) {
        COLOR = color_1;
    } else if (UV.y < break_2) {
        COLOR = color_2;
    } else if (UV.y < break_3) {
        COLOR = color_3;
    } else if (UV.y < break_4) {
        COLOR = color_4;
    } else if (UV.y < break_5) {
        COLOR = color_5;
    } else {
        COLOR = color_6; 
    }
	
}