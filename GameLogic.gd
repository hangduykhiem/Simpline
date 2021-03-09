extends Node

var GRID_NUMBER = 9
var _astar = AStar2D.new()
export (int) var grid_size

var _ball_grid = []

func generate_grid():
    for i in range(grid_size):
        for j in range(grid_size):
            _astar.add_point(i * grid_size + j, Vector2(i,j))
            _ball_grid.append(null)
    for i in range(grid_size):
        for j in range(grid_size):
            var current_point = i * grid_size + j
            if i + 1 < grid_size:
                var neighbor_right = _get_id_from_pos(i + 1, j)
                _astar.connect_points(current_point, neighbor_right)
            if j + 1 < grid_size:
                var neighbor_bottom = _get_id_from_pos(i, j + 1)
                _astar.connect_points(current_point, neighbor_bottom)


func put_ball(pos, ball):
    var id = _get_id_from_pos(pos.x, pos.y)
    if (_ball_grid[id] == null):
        _ball_grid[id] = ball
        _astar.set_point_disabled(id, true)
    else:
        push_error("There is already another ball in that position")


func has_ball(pos):
    return _ball_grid[_get_id_from_pos(pos.x, pos.y)] != null


func move_ball(pos, new_pos):
    var id = _get_id_from_pos(pos.x, pos.y)
    var new_id = _get_id_from_pos(new_pos.x, new_pos.y)
    if (_ball_grid[id] == null):
        push_error("There is no ball at position:  %s" % pos)
    if (_ball_grid[new_id] != null):
        push_error("There is already another ball in that position")
    _ball_grid[new_id] = _ball_grid[id]
    _ball_grid[id] = null
    _astar.set_point_disabled(id, false)
    _astar.set_point_disabled(new_id, true)


func remove_ball(pos):
    var id = _get_id_from_pos(pos.x, pos.y)
    var ball = _ball_grid[id]
    _ball_grid[id] = null
    ball.queue_free()
    _astar.set_point_disabled(id, false)


func get_ball(pos):
    return _ball_grid[_get_id_from_pos(pos.x, pos.y)]


func find_path(from_pos, to_pos):
    var from_id = _get_id_from_pos(from_pos.x, from_pos.y)
    var to_id = _get_id_from_pos(to_pos.x, to_pos.y)
    var path = _astar.get_point_path(from_id, to_id)
    if (path.size() == 0): return null
    return _simplify_astar_path(path)


func check_score(ball, pos):
    var color = ball.color

    # These variable store the ball rows, in order.
    var row = []
    var column = []
    var top_bottom = []
    var bottom_top = []

    # These variables finds the start of the diagonal rows to check
    var top_bottom_start
    var bottom_top_start
    if (pos.x > pos.y):
        top_bottom_start = Vector2(pos.x - pos.y, 0)
    else :
        top_bottom_start = Vector2(0, pos.y - pos.x)

    if (pos.x + pos.y < 9):
        bottom_top_start = Vector2(0, pos.x + pos.y)
    else:
        bottom_top_start = Vector2((pos.x + pos.y - 8), (pos.x + pos.y) - ((pos.x + pos.y) - 8))

    for i in GRID_NUMBER:
        row.append(Vector2(i, pos.y))
        column.append(Vector2(pos.x, i))
        if (top_bottom_start.x + i < 9 && top_bottom_start.y + i < 9):
            top_bottom.append(Vector2(top_bottom_start.x + i, top_bottom_start.y + i))
        if (bottom_top_start.x + i < 9 && bottom_top_start.y - i >= 0):
            bottom_top.append(Vector2(bottom_top_start.x + i, bottom_top_start.y - i))

    var result = []
    result = result + _check_row_for_score(row, color)
    result = result + _check_row_for_score(column, color)
    result = result + _check_row_for_score(top_bottom, color)
    result = result + _check_row_for_score(bottom_top, color)

    if (pos in result):
        while (pos in result):
            result.erase(pos) #Ball can be duplicated, so erase them, and add.
        result.append(pos)
    return result


func _check_row_for_score(row, color):
    var lines = []
    var last_color_index = -1
    var first_color_index = -1
    for i in row.size():
        var id = _get_id_from_pos(row[i].x, row[i].y)
        var ball = _ball_grid[id]
        if ball != null && ball.color == color:
            last_color_index = i
            if first_color_index == -1:
                first_color_index = i

            if last_color_index - first_color_index == 4:
                lines = [row[i], row[i-1], row[i-2], row[i-3], row[i-4]]
            elif last_color_index - first_color_index > 4:
                lines.append(row[i])
        else:
            first_color_index = -1
            last_color_index = -1
    return lines


func _get_id_from_pos(x, y):
    return x * grid_size + y


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
    return result
