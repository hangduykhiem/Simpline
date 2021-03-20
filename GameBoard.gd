##
# This scene's job is to animate the board, the UI, ball and their appearance /
# disappearance / movement.
# Actual game logics, like where ball should appear, are in the GameLogic.gd
# class.
##

extends Node2D

signal _ball_movement_anim_complete

var CELL_SIDE = 60
var GRID_NUMBER = 9
var LINE_LENGTH = CELL_SIDE * GRID_NUMBER
var MARGIN_VERTICAL = (1024 - LINE_LENGTH) / 2 # Screen height = 600
var MARGIN_HORIZONTAL = (600 - LINE_LENGTH) / 2


var GameLogic = load("GameLogic.gd")
var Ball = preload("Ball.tscn")

var _rng = RandomNumberGenerator.new()
var _gl = GameLogic.new()

var _moving = false
var _selected_pos
var _score = 0
var _all_balls = {}
var _next_balls = {}
var _ball_to_remove = []
var _cur_delay = 0

func _ready():
    _rng.randomize()
    _gl.grid_size = GRID_NUMBER
    _gl.connect("balls_appear", self, "_animate_balls_appearing")
    _gl.connect("ball_moved", self, "_animate_balls_movement")
    _gl.connect("lines_matched", self, "_animate_lines_clear")
    _gl.connect("next_balls_growth", self, "_animate_next_balls_growth")
    _gl.connect("movement_ended", self, "_handle_movement_ended")
    _gl.connect("game_over", self, "_handle_game_over")
    _gl.init()
    $HUD/GameOver.hide()
    _moving = true


func _input(event):
    if event is InputEventMouseButton && event.pressed && !_moving:
        var pos = _calculate_click_position(event.position)
        if (pos != null):
            if (_selected_pos != null):
                var selected_ball = _all_balls[Vector2(_selected_pos.x, _selected_pos.y)]
                selected_ball.toggle_selected()
                if (!_all_balls.has(pos)):
                    _moving = true
                    _gl.move_ball(_selected_pos, pos)
                    _selected_pos = null
                    return

            if (_all_balls.has(pos)):
                _all_balls[pos].toggle_selected()
                _selected_pos = pos
            else:
                _selected_pos = null
        else:
            _gl.print_all_pos()


func _animate_balls_movement(path):
    var ball = _all_balls[path[0]]

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
    _all_balls[path[path.size() -1]] = _all_balls[path[0]]
    _all_balls.erase(path[0])
    _cur_delay = _cur_delay + path.size() * 0.15


func _animate_lines_clear(lines):
    for ball_pos in lines:
        var ball = _all_balls[ball_pos]
        $Tween.interpolate_property(ball, "scale:x", 1, 0, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, _cur_delay)
        $Tween.interpolate_property(ball, "scale:y", 1, 0, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, _cur_delay)
        _ball_to_remove.append(_all_balls[ball_pos])
        _all_balls.erase(ball_pos)
    _cur_delay += 0.5


func _animate_balls_appearing(balls: Dictionary, next_ball: bool) -> void:
    for pos in balls.keys():
        var ball = Ball.instance()
        ball.color = balls[pos]
        ball.position = _calculate_center_position(pos.x, pos.y)
        ball.scale = Vector2(0,0)

        var new_scale := 0.0
        if (next_ball):
            new_scale = 0.5
            _next_balls[pos] = ball
        else:
            new_scale = 1
            _all_balls[pos] = ball

        add_child_below_node($Grid, ball)

        $Tween.interpolate_property(ball, "scale:x", 0, new_scale, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, _cur_delay)
        $Tween.interpolate_property(ball, "scale:y", 0, new_scale, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, _cur_delay)


##
# old_pos and new_pos arguments are only used in the case when one next_ball has
# been overlapped by a movement. In other cases, next_balls should just appear.
##
func _animate_next_balls_growth(old_pos, new_pos):
    if _next_balls.has(old_pos):
        var ball = _next_balls[old_pos]
        var new_position = _calculate_center_position(new_pos.x, new_pos.y)
        $Tween.interpolate_property(ball, "position", null, new_position, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, _cur_delay)
        $Tween.interpolate_property(ball, "scale:x", 0, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, _cur_delay)
        $Tween.interpolate_property(ball, "scale:y", 0, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, _cur_delay)
        _next_balls.erase(old_pos)
        _all_balls[new_pos] = ball

    for pos in _next_balls.keys():
        var ball = _next_balls[pos]
        _all_balls[pos] = ball
        $Tween.interpolate_property(ball, "scale:x", 0.5, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, _cur_delay)
        $Tween.interpolate_property(ball, "scale:y", 0.5, 1, .5, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, _cur_delay)

    _cur_delay += 0.5
    _next_balls.clear()


func _handle_movement_ended(score):
    $Tween.start()
    yield($Tween, "tween_all_completed")
    _cur_delay = 0
    _moving = false
    for ball in _ball_to_remove:
        if ball != null: ball.queue_free()
    $HUD.get_node("Score").text = ("%d" % score)


func _handle_game_over():
    yield($Tween, "tween_all_completed")
    $HUD/GameOver.show()

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

