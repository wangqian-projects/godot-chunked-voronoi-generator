extends Node2D

# 随机数种子的导出变量，用于生成随机数
export var randSeed:int

# 在此处声明成员变量。示例：
# var a = 2
# var b = "text"

# 显示一系列点的方法
# @param offset 用于对每个点的位置进行偏移的向量
# @param points 点的集合，每个点为Vector2类型
# @param color 点的颜色，默认为白色
func displayPoints(offset:Vector2, points:PoolVector2Array, color:Color = Color(1,1,1,1)):
    # 遍历所有点，并将它们作为多边形绘制出来
	for point in points:
		var newPointPoly = Polygon2D.new();
		newPointPoly.position = point + offset; # 对点进行偏移
		newPointPoly.polygon = PoolVector2Array([Vector2(-2,-2), Vector2(-2,2), Vector2(2,2), Vector2(2,-2)]); # 设置多边形形状
		newPointPoly.color = color; # 设置多边形颜色
		add_child(newPointPoly) # 将多边形添加到节点中

# 显示一个任意多边形的方法
# @param offset 用于对多边形的位置进行偏移的向量
# @param polygon 多边形的顶点集合，每个顶点为Vector2类型
func displayPolygon(offset:Vector2, polygon:PoolVector2Array):
    # 创建一个新的多边形并设置其顶点
	var newPoly = Polygon2D.new();
	var newPolyPoints = PoolVector2Array();
	for point in polygon:
		newPolyPoints.append(point + offset); # 对每个顶点进行偏移
	newPoly.polygon = newPolyPoints; # 设置新的多边形顶点集

	# 使用随机数种子设置多边形颜色
	var randGen = RandomNumberGenerator.new()
	randGen.seed = randSeed;
	newPoly.color = Color(randGen.randf(), randGen.randf(), randGen.randf(), 1);
	randSeed = randGen.randi(); # 更新随机数种子

	add_child(newPoly) # 将多边形添加到节点中

# 当节点首次进入场景树时被调用
func _ready():
    pass # 替换为函数体

# 每帧调用。'delta'是自前一帧以来经过的时间。
#func _process(delta):
#	pass
