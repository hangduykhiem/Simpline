extends Node2D

export (int) var color

var _ball_green_texture = preload("asset/green.png")
var _ball_red_texture = preload("asset/red.png")
var _ball_gray_texture = preload("asset/gray.png")
var _ball_purple_texture = preload("asset/purple.png")
var _ball_yellow_texture = preload("asset/yellow.png")
var _ball_pink_texture = preload("asset/pink.png")
var _ball_blue_texture = preload("asset/blue.png")
var _selected = false

func _ready():
    match color:
        0:
            $Sprite.texture = _ball_green_texture
        1:
            $Sprite.texture = _ball_red_texture
        2:
            $Sprite.texture = _ball_gray_texture
        3:
            $Sprite.texture = _ball_purple_texture
        4:
            $Sprite.texture = _ball_pink_texture
        5:
            $Sprite.texture = _ball_yellow_texture
        6:
            $Sprite.texture = _ball_blue_texture


func toggle_selected():
    _selected = !_selected
    if (_selected):
        $AnimationPlayer.play("selected")
    elif (!_selected):
        $AnimationPlayer.stop()
        $Sprite.rotation_degrees = 0
