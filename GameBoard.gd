extends Node2D

var CELL_SIDE = 60
var GRID_NUMBER = 9
var LINE_LENGTH = CELL_SIDE * GRID_NUMBER
var MARGIN_VERTICAL = (600 - LINE_LENGTH) / 2 # Screen height = 600
var MARGIN_HORIZONTAL = (1024 - LINE_LENGTH) / 2


var GameLogic = load("GameLogic.gd")
var Ball = preload("Ball.tscn")

var _rng = RandomNumberGenerator.new()
var _gl = GameLogic.new()

var _moving = false
var _current_selected_pos
var _next_ball = {}


func _ready():
    _rng.randomize()
    _gl.grid_size = GRID_NUMBER
    _gl.generate_grid()
    _init_balls()
    $Grid.position = Vector2(1024 / 2 , 600 /2 )


func _input(event):
    if event is InputEventMouseButton && event.pressed && !_moving:
        var pos = _calculate_click_position(event.position)
        if (pos != null):
            var ball = _gl.get_ball(pos)

            if (_current_selected_pos != null):
                var cur_x = _current_selected_pos.x
                var cur_y = _current_selected_pos.y
                _gl.get_ball(Vector2(cur_x, cur_y)).toggle_selected()
                if (ball == null):
                    _move_selected_ball(Vector2(pos.x, pos.y))

            if (ball != null):
                ball.toggle_selected()
                _current_selected_pos = Vector2(pos.x, pos.y)
            else:
                _current_selected_pos = null


func _init_balls():
    for _i in range(7):
        var x = _rng.randi_range(0,8)
        var y = _rng.randi_range(0,8)

        while (_gl.has_ball(Vector2(x,y))):
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
        _gl.put_ball(Vector2(x,y), ball)
    yield($Tween, "tween_all_completed")
    _get_next_balls()


func _get_next_balls():
    _moving = true
    _next_ball.clear()
    while(_next_ball.size() < 3):
        var x = _rng.randi_range(0,8)
        var y = _rng.randi_range(0,8)

        while _gl.has_ball(Vector2(x,y)) || _next_ball.has(Vector2(x,y)):
            x = _rng.randi_range(0,8)
            y = _rng.randi_range(0,8)

        var color = _rng.randi_range(0,6)
        var ball = Ball.instance()
        ball.color = color
        ball.position = _calculate_center_position(x, y)
        ball.scale = Vector2(0,0)
        add_child_below_node($Grid, ball)
        _next_ball[Vector2(x, y)] = ball
        $Tween.interpolate_property(ball, "scale:x", 0, .5, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
        $Tween.interpolate_property(ball, "scale:y", 0, .5, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)

    $Tween.start()
    yield($Tween, "tween_all_completed")
    _moving = false

func _move_selected_ball(pos):
    _moving = true
    var from_pos = Vector2(_current_selected_pos.x, _current_selected_pos.y)
    var ball = _gl.get_ball(from_pos)
    var path = _gl.find_path(from_pos, pos)
    if (path != null):
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
    yield($Tween, "tween_all_completed")

    _gl.move_ball(path[0], path[path.size() -1])
    var result = _gl.check_score(ball, path[path.size() -1]) # TODO: Use signal to put this to _move_selected_ball()
    if (result.size() > 0):
        _animate_clear(result)
    else:
        _animate_new_ball()


func _animate_clear(result):
    for ball_pos in result:
        var ball = _gl.get_ball(ball_pos)
        $Tween.interpolate_property(ball, "scale:x", 1, 0, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
        $Tween.interpolate_property(ball, "scale:y", 1, 0, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
    $Tween.start()

    yield($Tween, "tween_all_completed")
    for ball_pos in result:
        _gl.remove_ball(ball_pos)

    _moving = false

func _animate_new_ball():
    var new_pos = []
    for key in _next_ball.keys():
        var pos = key
        var ball = _next_ball[key]

        while (_gl.has_ball(pos)):
            var x = _rng.randi_range(0,8)
            var y = _rng.randi_range(0,8)
            pos = Vector2(x,y)
            while (pos in _next_ball.keys()):
                x = _rng.randi_range(0,8)
                y = _rng.randi_range(0,8)
                pos = Vector2(x,y)

        ball.position = _calculate_center_position(pos.x, pos.y)
        _gl.put_ball(pos, ball)
        new_pos.append(pos)
        $Tween.interpolate_property(ball, "scale:x", .5, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)
        $Tween.interpolate_property(ball, "scale:y", .5, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, 0)

    $Tween.start()
    yield($Tween, "tween_all_completed")

    for pos in new_pos:
        var ball = _gl.get_ball(pos)
        if (ball != null): #Can be null since two new ball can clear same row
            var result = _gl.check_score(ball, pos)
            _animate_clear(result)
    _moving = false
    _get_next_balls()


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

