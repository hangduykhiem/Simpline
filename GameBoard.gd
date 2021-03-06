extends Node2D

var CELL_SIDE = 60
var GRID_NUMBER = 9
var LINE_LENGTH = CELL_SIDE * GRID_NUMBER
var MARGIN_VERTICAL = (600 - LINE_LENGTH) / 2 # Screen height = 600
var MARGIN_HORIZONTAL = (1024 - LINE_LENGTH) / 2


var PathFinder = load("PathFinder.gd")
var Ball = preload("Ball.tscn")

var _rng = RandomNumberGenerator.new()
var _pf = PathFinder.new()

var _moving = false
var _ball_grid = []
var _current_selected_pos
var _next_ball = {}


func _ready():
    _rng.randomize()
    _pf.grid_size = GRID_NUMBER
    _pf.generate_grid()
    _init_ball_array()
    _init_balls()
    $Grid.position = Vector2(1024 / 2 , 600 /2 )


func _input(event):
    if event is InputEventMouseButton && event.pressed && !_moving:
        var pos = _calculate_click_position(event.position)
        if (pos != null):
            var ball = _ball_grid[pos.x][pos.y]

            if (_current_selected_pos != null):
                var cur_x = _current_selected_pos.x
                var cur_y = _current_selected_pos.y
                _ball_grid[cur_x][cur_y].toggle_selected()
                if (ball == null):
                    _move_selected_ball(Vector2(pos.x, pos.y))

            if (ball != null):
                ball.toggle_selected()
                _current_selected_pos = Vector2(pos.x, pos.y)
            else:
                _current_selected_pos = null


func _init_ball_array():
    for i in range(GRID_NUMBER):
        _ball_grid.append([])
        for _j in range(GRID_NUMBER):
            _ball_grid[i].append(null)


func _init_balls():
    for _i in range(20):
        var x = _rng.randi_range(0,8)
        var y = _rng.randi_range(0,8)

        while (_ball_grid[x][y] != null):
            x = _rng.randi_range(0,8)
            y = _rng.randi_range(0,8)

        var color = _rng.randi_range(0,6)
        var ball = Ball.instance()
        ball.color = color
        ball.position = _calculate_center_position(x, y)
        ball.scale = Vector2(0,0)
        $Tween.interpolate_property(ball, "scale:x", 0, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
        $Tween.interpolate_property(ball, "scale:y", 0, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
        $Tween.start()
        add_child(ball)
        _ball_grid[x][y] = ball
        _pf.set_position_disabled(x, y, true)
    yield($Tween, "tween_all_completed")
    _get_next_balls()


func _get_next_balls():
     _next_ball.clear()
     for _i in range(3):
        var x = _rng.randi_range(0,8)
        var y = _rng.randi_range(0,8)

        while (_ball_grid[x][y] != null):
            x = _rng.randi_range(0,8)
            y = _rng.randi_range(0,8)

        var color = _rng.randi_range(0,6)
        var ball = Ball.instance()
        ball.color = color
        ball.position = _calculate_center_position(x, y)
        ball.scale = Vector2(0,0)

        $Tween.interpolate_property(ball, "scale:x", 0, .5, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
        $Tween.interpolate_property(ball, "scale:y", 0, .5, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
        add_child_below_node($Grid, ball)
        $Tween.start()
        _next_ball[Vector2(x, y)] = ball

func _move_selected_ball(pos):
    _moving = true
    var ball = _ball_grid[_current_selected_pos.x][_current_selected_pos.y]
    var from_pos = Vector2(_current_selected_pos.x, _current_selected_pos.y)
    var path = _pf.find_path(from_pos, pos)
    if (path != null):
        _ball_grid[from_pos.x][from_pos.y] = null
        _ball_grid[pos.x][pos.y] = ball
        _pf.set_position_disabled(from_pos.x, from_pos.y, false)
        _pf.set_position_disabled(pos.x, pos.y, true)
        _animate_movement(path, ball)
    else:
        _moving = false

func _animate_movement(path, ball):
    var i = 1
    while (i < path.size()):
        var cur_pos = path[i]
        var prev_pos = path[i-1]
        $Tween.interpolate_property(ball, "position",
            _calculate_center_position(prev_pos.x, prev_pos.y),
            _calculate_center_position(cur_pos.x, cur_pos.y),
            0.15, Tween.TRANS_CUBIC, Tween.EASE_OUT, (i - 1) * 0.15
        )
        i += 1
    $Tween.interpolate_property(ball, "rotation_degrees", 0, 360, (path.size() * 0.15), Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
    $Tween.start()
    $Tween.connect("tween_all_completed", self, "_on_animation_end", [ball, path[path.size() -1]])


func _on_animation_end(ball, pos):
    _check_score(ball, pos)
    $Tween.disconnect("tween_all_completed", self, "_on_animation_end")
    pass


# TODO: Move this to another script like PathFinder
func _check_score(ball, pos):
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

    if (ball in result):
        while (ball in result):
            result.erase(ball) #Ball can be duplicated, so erase them, and add.
        result.append(ball)

    print(result)
    _animate_clear_or_new_ball(result)


func _check_row_for_score(row, color):
    var lines = []
    var last_color_index = -1
    var first_color_index = -1
    for i in row.size():
        var ball = _ball_grid[row[i].x][row[i].y]
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


func _animate_clear_or_new_ball(result):
    if (result.size() == 0):
        for key in _next_ball.keys():
            var pos = key
            var ball = _next_ball[key]

            while (_ball_grid[pos.x][pos.y] != null):
                var x = _rng.randi_range(0,8)
                var y = _rng.randi_range(0,8)
                pos = Vector2(x,y)

            ball.position = _calculate_center_position(pos.x, pos.y)
            _ball_grid[pos.x][pos.y] = ball
            _pf.set_position_disabled(pos.x, pos.y, true)
            $Tween.interpolate_property(ball, "scale:x", .5, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
            $Tween.interpolate_property(ball, "scale:y", .5, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)

        $Tween.start()
        yield($Tween, "tween_all_completed")
        _get_next_balls()

    else:
        for ball_pos in result:
            var ball = _ball_grid[ball_pos.x][ball_pos.y]
            $Tween.interpolate_property(ball, "scale:x", 1, 0, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
            $Tween.interpolate_property(ball, "scale:y", 1, 0, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
        $Tween.start()

        yield($Tween, "tween_all_completed")
        for ball_pos in result:
            var ball = _ball_grid[ball_pos.x][ball_pos.y]
            _ball_grid[ball_pos.x][ball_pos.y] = null
            ball.queue_free()
            _pf.set_position_disabled(ball_pos.x, ball_pos.y, false)
    _moving = false


func _calculate_center_position(x, y):
    var pos_x = MARGIN_HORIZONTAL + x * CELL_SIDE + CELL_SIDE / 2
    var pos_y = MARGIN_VERTICAL + y * CELL_SIDE + CELL_SIDE / 2
    return Vector2(pos_x, pos_y)


func _calculate_click_position(pos):
    var x = floor((pos.x - MARGIN_HORIZONTAL) / CELL_SIDE)
    var y = floor((pos.y - MARGIN_VERTICAL) / CELL_SIDE)
    if x < 0 || x >= 9:
        return null
    if y < 0 || y >= 9:
        return null
    return Vector2(x, y)

