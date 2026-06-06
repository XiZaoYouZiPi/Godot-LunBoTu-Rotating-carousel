extends Node2D

@export_group("操作参数")
## 卡牌拖动时的速度，值为 0.0 时将不再受到拖拽影响，此值不影响甩动旋转
@export_range(0,10,0.01) var 拖动速度系数:float = 1
## 卡牌旋转时的速度，值为 0.0 时将不再旋转，只将受到拖拽影响
@export_range(0,1,0.01) var 旋转速度系数:float = 1
## 卡牌旋转时会受到的速度衰减，值越小旋转速度衰减越小，
## 如需卡牌永久旋转不停效果，可在代码将取值范围设置到 0.0 ，取值为 0.0 时将不会受到衰减，
## 如需卡牌旋转加速，可在代码将取值范围设置到负数，不过不建议设置为负数，因为将不会停止加速
@export_range(0,10,0.01) var 旋转速度衰减: float = 10
## 复位时的速度值，为 0.0 时将不会进行复位
@export_range(0,10,0.01) var 复位速度:float = 5
## 卡牌复位时的最小偏差值，为 0.0 时完全复位，值过小时复位会有锯齿感
@export_range(0,0.01,0.001) var 复位修正最小值:float = 0.01
@export var 点击移至顶牌: bool = true
@export_range(0,PI,0.01) var 点击移至顶牌的执行范围: float = PI
@export_range(0,5,0.01) var 点击移至顶牌的旋转时间: float = 1

@export_group("椭圆参数")
## 值为 ture 时可见椭圆，椭圆显示的精度与“采样点数量”属性正相关
@export var 显示椭圆轮廓: bool = false
## 椭圆的中心点位置，因为与“卡牌通用大小”属性存在关联性，
## 所以会略有偏差，建议先确定卡牌大小再确定椭圆的位置
@export var 椭圆中心: Vector2 = Vector2(0,0)
## 椭圆的 x半轴 长度，两轴更长者为椭圆的长半轴，两轴相等时椭圆将为圆，两轴则为圆的半径
@export var x半轴: float = 400
## 椭圆的 y半轴 长度，两轴更长者为椭圆的长半轴，两轴相等时椭圆将为圆，两轴则为圆的半径
@export var y半轴: float = 200
## 此属性只在“显示椭圆轮廓”属性为 ture 时，显示椭圆的精度有关，并不影响卡牌位置计算的精度等
@export var 采样点数量: int = 300

@export_group("卡牌参数")
## 为每一个卡牌配置纹理，纹理数量大于“卡牌数量”属性时增加卡牌数量，
## 游戏运行后将不可在编辑器中设值，编辑器改值需重新运行场景，
## 运行时脚本进行更改不受影响 
@export var 卡牌纹理数组:Array[Texture]
## 所有卡牌的通用大小，更改可能会影响椭圆的位置，建议先确定卡牌大小再确定椭圆的位置
@export var 卡牌通用大小: Vector2 = Vector2(50, 100)
## 未通过“卡牌纹理数组”配置的多余卡牌，将使用通用纹理
@export var 卡牌通用纹理: Texture
## 设置圆上卡牌的数量，当值小于“卡牌纹理数组”的数量时，值将更改为“卡牌纹理数组”的数量，
## 当值大于“卡牌纹理数组”的数量时，多余卡牌将使用“卡牌通用纹理”属性作为卡牌纹理,
## 需要注意的是，它会在游戏开始时补充“卡牌纹理数组”的数量，造成无法减少卡牌数量至初始以下的情况，
## 所以，编辑器减少值至初始值以下时需重新运行场景，编辑器增加值时进行更改不受影响
@export var 卡牌最小数量: int = 10
## 设置顶牌在圆上方还是下方
@export var 下弦在前: bool = true
## 让顶牌周围的牌远离或更接近顶牌
@export_range(-1,1,0.01) var 步长偏移系数: float = 0
## 特殊属性，与“透视效果系数”配合会有一些奇怪的效果，如该属性设置为 0.5 ，"透视效果系数"为 1 时。
@export_range(-1,1,0.01) var 透视颠倒减数: float = 1
## 添加近大远小的效果，小于 0.0 时远大近小，会受到“下弦在前”属性的影响
@export_range(-1,1,0.01) var 透视效果系数: float = 0
## 设置顶牌是否受“透明效果系数”属性影响，一定程度会影响“透明效果系数”属性的效果
@export var 顶牌透明: bool = false
## 每一张卡牌在圆上位置的透明度大小系数，为 0.0 时则所有卡牌不透明
@export_range(-2.5,2.5,0.01) var 透明效果系数: float = 0
## 每一张卡牌在圆上位置的旋转值大小系数，为 0.0 时则所有卡牌不旋转
@export_range(-1,1,0.01) var 旋转偏移系数: float = 0

#运行所需变量，请不要随意更改
var 卡牌场景:TextureRect = TextureRect.new()
var 卡牌数组: Array = []
var 鼠标按下位置:Vector2
var 鼠标位置记录周期:bool = false
var 鼠标位置:Vector2
var 按下时长:int
var 位移向量距离:Vector2 = Vector2.ZERO
var 增量:float 
var 移动偏移量:float
var 是否正在拖动 = false
var 是否正在甩动 = false
var 甩动速度:float = 0
var 点击卡牌时位置:Vector2
var 移动卡牌补间动画:Tween 

signal 纹理数组增加纹理信号(纹理,位置)
signal 纹理数组删除纹理信号(纹理,起点)

signal 点击顶牌信号(卡牌)

func _ready():
	纹理数组增加纹理信号.connect(增加纹理数组纹理)
	纹理数组删除纹理信号.connect(删除纹理数组纹理)
	初始化椭圆和卡牌()

func _process(delta):
	更新卡牌数量()
	运行卡牌状态(delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if 拖动速度系数 == 0:
		return
	if event is InputEventMouse:
		鼠标位置 = event.position
	var 椭心至鼠向量 = 椭圆至鼠标向量()
	var 椭心至鼠长度 = 椭心至鼠向量.length()
	var 椭圆点 = (通过弧度获取椭圆上的点(通过点获取弧度(椭心至鼠向量+椭圆中心)+PI/2)-椭圆中心).length()
	var 不可滑动距离 = min(椭圆点-椭圆点*0.3, 椭圆点 - 100)

	if 椭心至鼠长度 <= 不可滑动距离:
		鼠标位置记录周期 = false
		增量 = 移动偏移量
	if event is InputEventMouseButton and event.button_index==1:
		var 按下时间:int
		if event.pressed :
			是否正在拖动 = true
			甩动速度 = 0
			鼠标位置记录周期 = false
			增量 = 移动偏移量
			位移向量距离 = Vector2.ZERO
			按下时间  = Time.get_ticks_msec()
			按下时长 = 按下时间
		else:
			是否正在拖动 = false
			增量 = 移动偏移量
			按下时长 = Time.get_ticks_msec() - 按下时长	
			甩动速度 = 位移向量距离.length() / 按下时长
			是否正在甩动 = true
	elif event is InputEventMouseMotion and 是否正在拖动 and 椭心至鼠长度 > 不可滑动距离:
		if not 鼠标位置记录周期:
			鼠标按下位置 = event.position
			鼠标位置记录周期 = true
		var 旋转弧度 = 通过点获取弧度(event.position) - 通过点获取弧度(鼠标按下位置)
		位移向量距离 = event.position - 鼠标按下位置
		拖动卡牌(旋转弧度)

func 初始化椭圆和卡牌():
	椭圆中心 -= 椭圆偏移修正()
	for i in range(卡牌最小数量):
		if 卡牌纹理数组.size() < 卡牌最小数量:
			纹理数组增加纹理信号.emit()
func 更新卡牌数量():
	if 卡牌纹理数组.size() >= 卡牌最小数量:
		卡牌最小数量 = 卡牌纹理数组.size()
	if 卡牌数组.size() < 卡牌最小数量:
		增加卡牌()
	if 卡牌数组.size() > 卡牌最小数量:
		删除卡牌()
func 运行卡牌状态(delta):
	for 卡牌 in 卡牌数组:
		更新卡牌透明度(卡牌)
		更新卡牌大小(卡牌)
		更新Z轴顺序(卡牌)
		更新卡牌旋转(卡牌)
	更新卡牌位置()
	偏移量恢复(delta)
	if not 是否正在拖动 and 是否正在甩动:
		甩动卡牌(delta)

func 拖动卡牌(旋转弧度):
	if 拖动速度系数 == 0:
		return
	移动偏移量 = 增量 - 旋转弧度*拖动速度系数
	if 移动卡牌补间动画 != null and 移动卡牌补间动画.is_valid():
		print("拖动时打断补间动画")
		移动卡牌补间动画.kill()
func 甩动卡牌(delta):
	甩动速度 = max(甩动速度 - 旋转速度衰减 * delta, 0)
	if 甩动速度 == 0:
		是否正在甩动 = false
	var 上负下正 = abs(鼠标按下位置.y-椭圆中心.y)/(鼠标按下位置.y-椭圆中心.y)
	var 左负右正 = abs(鼠标按下位置.x-椭圆中心.x)/(鼠标按下位置.x-椭圆中心.x)
	var 方向选定
	var 方向归一化
	if abs(位移向量距离.x)>abs(位移向量距离.y):
		方向选定 = 位移向量距离.normalized().x
		方向归一化 = 上负下正 * 方向选定
	else :
		方向选定 = 位移向量距离.normalized().y
		方向归一化 = -(左负右正 * 方向选定)
	移动偏移量 += 旋转速度系数*甩动速度*PI*方向归一化*delta 

func 偏移量恢复(delta):
	if 甩动速度 >= 复位速度 or 是否正在拖动:
		return
	var 需偏移修正值 = 至终点最小偏移量()
	if abs(需偏移修正值) <= 复位修正最小值 :
		需偏移修正值 = 0
	移动偏移量 += 旋转速度系数*需偏移修正值*复位速度*delta

func 更新卡牌位置():
	if 卡牌最小数量 <= 0:
		return
	var 常规步长 = 2 * PI / 卡牌最小数量
	var 计数:int = 0
	for 卡牌 in 卡牌数组:
		var 步长量 = 计数 * 常规步长 - 移动偏移量
		计数 += 1
		var 修正步长 = 卡牌步长修正(步长量)
		var 卡牌位置 = 通过弧度获取椭圆上的点(修正步长)
		卡牌.position = 卡牌位置 	
func 卡牌步长修正(常规步长:float):
	var 修正系数 = sin(常规步长)*步长偏移系数
	var 修正步长 = 常规步长 + 修正系数
	return 修正步长
func 获取修正后得到常规步长的步长(常规步长:float) -> float:
	var 修正前步长 = 常规步长
	var 最大迭代: int = 50
	var 精度: float = 1e-6
	for i in range(最大迭代):
		var 函数值 = 步长偏移系数*sin(修正前步长) + 修正前步长 - 常规步长
		var 函数值_导数 = 1.0 + 步长偏移系数 * cos(修正前步长)
		var 增量值 = 函数值 / 函数值_导数
		修正前步长 -= 增量值
		if abs(增量值) < 精度:
			return 修正前步长
	return 修正前步长
	
func 更新卡牌大小(卡牌: TextureRect):
	卡牌.size = 卡牌通用大小
	卡牌.pivot_offset = 卡牌.size / 2
	var 最终缩放 = Vector2(1, 1) * (透视颠倒减数-计算透视缩放(通过点获取弧度(卡牌.position)))
	卡牌.scale = 最终缩放
func 计算透视缩放(步长:float):
	var 缩放系数
	if 下弦在前:
		缩放系数 = (cos(步长+PI/2)+1)/2*透视效果系数
	else:
		缩放系数 = (cos(步长-PI/2)+1)/2*透视效果系数
	return 缩放系数

func 更新卡牌透明度(卡牌: TextureRect):
	var 透明度 = 1- 计算透明度(通过点获取弧度(卡牌.position))
	卡牌.modulate.a = 透明度
func 计算透明度(步长:float):
	if 透明效果系数 > 0 :
		var 透明度系数 = (cos(步长+PI/2)+1+int(顶牌透明)*透明效果系数)/2*透明效果系数
		return 透明度系数
	if 透明效果系数 < 0 :
		var 透明度系数 = (cos(步长-PI/2)+1-int(顶牌透明)*透明效果系数)/2*-透明效果系数 
		return 透明度系数
	return 0

func 更新卡牌旋转(卡牌: TextureRect):
	var 对应弧度 = (通过点获取弧度(卡牌.position))
	var 计算 = cos(对应弧度)*PI*旋转偏移系数
	卡牌.rotation = 计算

func 更新Z轴顺序(卡牌: TextureRect):
	var Z_索引值 = 计算Z轴顺序(通过点获取弧度(卡牌.position))
	卡牌.z_index = int(Z_索引值)
func 计算Z轴顺序(步长:float):
	var 索引
	if 下弦在前:
		索引 = abs((cos(步长+PI/2)-1)/2)*100
	else:
		索引 = (cos(步长+PI/2)+1)/2*100
	return 索引

func 增加卡牌():
	var 卡牌实例 = 卡牌场景.duplicate() as TextureRect
	卡牌实例.expand_mode = 1
	卡牌实例.texture = 卡牌通用纹理
	卡牌实例.size = 卡牌通用大小
	add_child(卡牌实例)
	卡牌数组.append(卡牌实例)
	卡牌实例.gui_input.connect(获取卡牌输入事件.bind(卡牌实例))
	替换卡牌纹理()
func 删除卡牌():
	var 卡牌实例 = 卡牌数组.pop_back()
	remove_child(卡牌实例)
	卡牌实例.queue_free()
	替换卡牌纹理()

func 替换卡牌纹理():
	for i in range(卡牌数组.size()):
		卡牌数组[i].texture = 卡牌纹理数组[i] if i < 卡牌纹理数组.size() else 卡牌通用纹理
func 增加纹理数组纹理(纹理:Texture=卡牌通用纹理,位置:int=-1):
	if 位置 == -1 or 位置 >= 卡牌纹理数组.size():
		卡牌纹理数组.append(纹理)
		return
	卡牌纹理数组.insert(位置, 纹理)
func 删除纹理数组纹理(纹理:Texture,起点:int=0):
	var 索引 = 卡牌纹理数组.find(纹理, 起点)
	if 索引 != -1:
		卡牌纹理数组.remove_at(索引)
		卡牌最小数量 = 卡牌纹理数组.size()

func 椭圆至鼠标向量() -> Vector2:
	var 鼠标向量 = 鼠标位置 - 椭圆中心 
	var 修正 = 鼠标向量 - 椭圆偏移修正()
	return 修正
func 通过弧度获取椭圆上的点(角度:float):
	var x = 椭圆中心.x + x半轴 * cos(角度-PI/2+PI*int(下弦在前))
	var y = 椭圆中心.y + y半轴 * sin(角度-PI/2+PI*int(下弦在前))
	return Vector2(x, y)
func 通过点获取弧度(点:Vector2):
	var dx = 点.x - 椭圆中心.x
	var dy = 点.y - 椭圆中心.y
	var 弧度 = atan2(dy/y半轴 , dx/x半轴) 
	return 弧度
func 至终点最小偏移量():
	var 最终弧度 = PI*int(下弦在前) - PI/2
	var 最小长度:float = INF
	var 最小偏移量:float = INF
	for 卡牌 in 卡牌数组:
		var 位置 = 卡牌.position
		var 对应弧度 = 通过点获取弧度(位置)
		var 长度 = abs(对应弧度 - 最终弧度)
		最小长度 = min(长度,最小长度)
		if 最小长度 == 长度:
			最小偏移量 = 对应弧度 - 最终弧度
	return 最小偏移量

func 获取卡牌输入事件(event: InputEvent, 卡牌: TextureRect) -> void:
	if event is InputEventMouseButton and event.button_index == 1 :
		if event.pressed:
			点击卡牌时位置 = 卡牌.position
		else:
			if 卡牌.position == 点击卡牌时位置:
				if 判断卡牌是否在顶牌位置(卡牌):
					点击顶牌信号.emit(卡牌)
				elif 点击移至顶牌:
					移动至顶牌(卡牌)
func 判断卡牌是否在顶牌位置(卡牌: TextureRect) -> bool:
	var 对应弧度 = 通过点获取弧度(卡牌.position)+PI/2-PI*int(下弦在前)
	if 至终点最小偏移量() == 对应弧度:
		return true
	return false
func 移动至顶牌(卡牌: TextureRect):
	var 对应弧度 = 通过点获取弧度(卡牌.position)
	var 最终弧度 = PI*int(下弦在前) - PI/2
	var 需移动偏移量 = 对应弧度 - 最终弧度
	if abs(需移动偏移量) >= 点击移至顶牌的执行范围:
		return
	移动卡牌补间动画 = create_tween()
	移动卡牌补间动画.set_trans(Tween.TRANS_BACK)
	移动卡牌补间动画.set_ease(Tween.EASE_OUT)
	var 修正前偏移量 = 获取修正后得到常规步长的步长(需移动偏移量)
	移动卡牌补间动画.tween_property(self, "移动偏移量", 移动偏移量+修正前偏移量,点击移至顶牌的旋转时间/旋转速度系数)

func 椭圆偏移修正():
	return 卡牌通用大小/2
func _draw() -> void:
	if !显示椭圆轮廓:
		return
	var 步长 = 2 * PI/采样点数量
	var 点列表 = []
	for i in range(采样点数量 + 1):
		var 角度 = i * 步长
		var 点 = 通过弧度获取椭圆上的点(角度) + 椭圆偏移修正()
		点列表.append(点)
	for i in range(点列表.size() - 1):
		draw_line(点列表[i], 点列表[i + 1], Color(1, 0, 0), 2)
