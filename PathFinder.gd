extends Node

var _astar = AStar2D.new()
export (int) var grid_size

func generate_grid():
    for i in range(grid_size):
        for j in range(grid_size):
            _astar.add_point(i * grid_size + j, Vector2(i,j))
    for i in range(grid_size):
        for j in range(grid_size):
            var current_point = i * grid_size + j
            if i + 1 < grid_size:
                var neighbor_right = _get_id_from_pos(i + 1, j)
                _astar.connect_points(current_point, neighbor_right)
            if j + 1 < grid_size:
                var neighbor_bottom = _get_id_from_pos(i, j + 1)
                _astar.connect_points(current_point, neighbor_bottom)


func find_path(from_pos, to_pos):
    var from_id = _get_id_from_pos(from_pos.x, from_pos.y)
    var to_id = _get_id_from_pos(to_pos.x, to_pos.y)
    var path = _astar.get_point_path(from_id, to_id)
    if (path.size() == 0): return null
    return _simplify_astar_path(path)


func set_position_disabled(x, y, disable):
    _astar.set_point_disabled(_get_id_from_pos(x, y), disable)


func _get_id_from_pos(x, y):
    return x * grid_size + y


func _get_pos_from_id(id):
    var x = floor(id / grid_size)
    var y = id - (x * grid_size)
    return Vector2(x , y)


func _simplify_astar_path(path):
    var i = 1
    var result = [path[0]]

    var previousDir
    while (i < path.size()):
        var currentPoint = path[i]
        var previousPoint = path[i-1]
        var currentDir
        if (currentPoint.x == previousPoint.x):
            currentDir = VERTICAL
        else:
            currentDir = HORIZONTAL
        if (previousDir == null):
            previousDir = currentDir
        if (currentDir != previousDir):
            result.append(previousPoint)
            previousDir = currentDir
        i += 1

    result.append(path[path.size() -1])
    print("Origin Path: ", path)
    print("Result Path: ", result)
    return result
