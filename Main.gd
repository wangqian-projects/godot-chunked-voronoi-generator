# 此脚本扩展于Node，用于生成和显示基于Voronoi图的区域划分。
extends Node;

# 导出的变量用于配置生成。
export var randomSeed:int; # 随机种子，用于生成随机数。
export var widthPerChunk: int = 5; # 每个区块的宽度。
export var heightPerChunk: int = 5; # 每个区块的高度。
export var distBtwPoints: float = 30; # 点之间的距离基础值。
export var distBtwVariation: float = .3; # 点之间距离的随机变化值。
export var voronoiTolerance:float = .3; # Voronoi图边界的容忍度。

var view; # 用于显示的视图对象。

# 根据坐标和初始种子生成一个随机数。
func randomNumOnCoords(coords:Vector2, initialSeed:int):
    var result = initialSeed
    var randGen = RandomNumberGenerator.new();
    randGen.seed = coords.x;
    result += randGen.randi();
    var newy = randGen.randi() + coords.y;
    randGen.seed = newy;
    result += randGen.randi();
    randGen.seed = result;
    result = randGen.randi();
    return result;

# 为指定区块生成点集合。
func generateChunkPoints(coords:Vector2, wRange:Vector2=Vector2(0, widthPerChunk), hRange:Vector2=Vector2(0, heightPerChunk)):
    var localRandSeed = randomNumOnCoords(coords, randomSeed);
    var initPoints = PoolVector2Array();
    for w in range(wRange.x, wRange.y):
        for h in range(hRange.x, hRange.y):
            var randGen = RandomNumberGenerator.new();
            var pointRandSeed = randomNumOnCoords(Vector2(w,h), localRandSeed);
            randGen.seed = pointRandSeed;
            var newPoint = Vector2(w*distBtwPoints + randGen.randf_range(-distBtwVariation, distBtwVariation)*distBtwPoints, h*distBtwPoints + randGen.randf_range(-distBtwVariation, distBtwVariation)*distBtwPoints);
            initPoints.append(newPoint)
    return initPoints;

# 为指定区块生成Voronoi图。
func generateChunkVoronoi(coords:Vector2):
    var initPoints = generateChunkPoints(coords);
    var sorroundingPoints = PoolVector2Array();
    for i in range(-1, 2):
        for j in range(-1, 2):
            if (!(i == 0 && j == 0)):
                var xmin = 0;
                var xmax = 1;
                var ymin = 0;
                var ymax = 1;
                if (i == -1):
                    xmin = 1 - voronoiTolerance;
                if (i == +1):
                    xmax = voronoiTolerance;
                if (j== -1):
                    ymin = 1 - voronoiTolerance;
                if (j== 1):
                    ymax = voronoiTolerance;
                var tempPoints = generateChunkPoints(Vector2(coords.x+i, coords.y+j), Vector2(xmin*widthPerChunk, xmax*widthPerChunk), Vector2(ymin*heightPerChunk, ymax*heightPerChunk));
                var resultPoints = PoolVector2Array();
                for point in tempPoints:
                    var tempPoint = point + Vector2(i * widthPerChunk * distBtwPoints, j * heightPerChunk * distBtwPoints);
                    resultPoints.append(tempPoint);
                sorroundingPoints.append_array(resultPoints)
    var allPoints = initPoints+sorroundingPoints;
    var allDelauney = Geometry.triangulate_delaunay_2d(allPoints);
    var triangleArray = [];
    for triple in range(0, allDelauney.size()/3):
        triangleArray.append([allDelauney[triple*3], allDelauney[triple*3+1], allDelauney[triple*3+2]]);
    var circumcenters = PoolVector2Array();
    for triangle in triangleArray:
        circumcenters.append(getCircumcenter(allPoints[triangle[0]], allPoints[triangle[1]], allPoints[triangle[2]]));
    var vCtrIdxWithVerts = [];
    for point in range(initPoints.size()):
        var tempVerts = PoolVector2Array();
        for triangle in range(triangleArray.size()):
            if (point == triangleArray[triangle][0] || point == triangleArray[triangle][1] || point == triangleArray[triangle][2]):
                tempVerts.append(circumcenters[triangle]);
        tempVerts = clowckwisePoints(initPoints[point], tempVerts)
        vCtrIdxWithVerts.append([initPoints[point], tempVerts]);

    return vCtrIdxWithVerts;

# 将点集绕着中心点按顺时针排序。
func clowckwisePoints(center:Vector2, sorrounding:PoolVector2Array):
    var result = PoolVector2Array();
    var angles = PoolRealArray();
    var sortedIndexes = PoolIntArray();
    for point in sorrounding:
        angles.append(center.angle_to_point(point));
    var remainingIdx = PoolIntArray();
    for angle in range(angles.size()):
        remainingIdx.append(angle);
    for angle in range(angles.size()):
        var currentMin = PI;
        var currentTestIdx = 0;
        for test in range(remainingIdx.size()):
            if (angles[remainingIdx[test]] < currentMin):
                currentTestIdx = test;
                currentMin = angles[remainingIdx[test]];
        sortedIndexes.append(remainingIdx[currentTestIdx]);
        remainingIdx.remove(currentTestIdx);
    for index in sortedIndexes:
        result.append(sorrounding[index]);
    return result;

# 计算三角形的外接圆中心点。
func getCircumcenter(a:Vector2, b:Vector2, c:Vector2):
    var result = Vector2(0,0)
    var midpointAB = Vector2((a.x+b.x)/2,(a.y+b.y)/2);
    var slopePerpAB = -((b.x-a.x)/(b.y-a.y));
    var midpointAC = Vector2((a.x+c.x)/2,(a.y+c.y)/2);
    var slopePerpAC = -((c.x-a.x)/(c.y-a.y));
    var bOfPerpAB = midpointAB.y - (midpointAB.x * slopePerpAB);
    var bOfPerpAC = midpointAC.y - (midpointAC.x * slopePerpAC);
    result.x = (bOfPerpAB - bOfPerpAC)/(slopePerpAC - slopePerpAB);
    result.y = slopePerpAB*result.x + bOfPerpAB;
    return result;

# 根据区块位置显示Voronoi图。
func displayVornoiFromChunk(chunkLoc:Vector2):
    view = get_child(0)
    view.randSeed = randomNumOnCoords(chunkLoc, randomSeed);
    var voronoi = generateChunkVoronoi(chunkLoc);
    for each in voronoi:
        view.displayPolygon(Vector2(chunkLoc.x*widthPerChunk*distBtwPoints,chunkLoc.y*heightPerChunk*distBtwPoints), each[1]);
    view.displayPoints(Vector2(chunkLoc.x*widthPerChunk*distBtwPoints,chunkLoc.y*heightPerChunk*distBtwPoints), generateChunkPoints(chunkLoc))
    pass

# 初始化函数，为每个指定的区块位置显示Voronoi图。
func _ready():
    for w in 10:
        for h in 10:
            if (w == 5 && h == 5):
                null;
            else:
                displayVornoiFromChunk(Vector2(w, h));
    pass;
