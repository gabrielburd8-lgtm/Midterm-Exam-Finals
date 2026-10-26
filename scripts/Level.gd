extends Node2D

@onready var ball: RigidBody2D = $Ball
@onready var trajectory: Node2D = $Trajectory
@onready var shot_label: Label = $UI/ShotLabel
@onready var target_label: Label = $UI/TargetLabel
@onready var complete_label: Label = $UI/CompleteLabel
@onready var restart_button: Button = $UI/RestartButton
@onready var main_menu_button: Button = $UI/MainMenuButton
@onready var ball_spawn: Marker2D = $BallSpawn

var dragging := false
var shot_count := 0
var game_over := false

func _ready() -> void:
    ball.position = ball_spawn.position
    ball.reset_motion()
    ball.freeze = true

    ball.body_entered.connect(_on_ball_body_entered)
    restart_button.pressed.connect(_on_restart_pressed)
    main_menu_button.pressed.connect(_on_main_menu_pressed)

    restart_button.visible = false
    main_menu_button.visible = false
    complete_label.visible = false

    _update_ui()
    _update_trajectory()

func _input(event: InputEvent) -> void:
    if game_over:
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var mouse_pos = get_global_mouse_position()

        if event.pressed:
            if _can_drag_ball() and ball.global_position.distance_to(mouse_pos) < 140.0:
                dragging = true
                ball.freeze = true
                ball.linear_velocity = Vector2.ZERO
                ball.angular_velocity = 0.0
        elif dragging:
            _launch_ball()

    if event is InputEventKey and event.pressed and event.keycode == KEY_R:
        _restart_level()

func _process(_delta: float) -> void:
    if game_over:
        return

    if dragging:
        _update_trajectory()

    if ball.global_position.y > 900:
        _trigger_lose()

func _can_drag_ball() -> bool:
    return not ball.is_moving() and not dragging and not game_over

func _launch_ball() -> void:
    if not dragging:
        return

    var pull = ball.global_position - get_global_mouse_position()
    if pull.length() < 16.0:
        dragging = false
        ball.freeze = true
        _update_trajectory()
        return

    var launch_velocity = pull * 4.2
    ball.freeze = false
    ball.linear_velocity = launch_velocity
    ball.angular_velocity = 0.0
    ball.sleeping = false
    dragging = false
    shot_count += 1
    _update_ui()
    _update_trajectory()

func _update_trajectory() -> void:
    if not dragging:
        trajectory.points = PackedVector2Array()
        trajectory.queue_redraw()
        return

    var drag = ball.global_position - get_global_mouse_position()
    if drag.length() < 10.0:
        trajectory.points = PackedVector2Array()
        trajectory.queue_redraw()
        return

    var velocity = drag * 4.2
    var pos = ball.global_position
    var points: PackedVector2Array = PackedVector2Array()

    for i in range(18):
        points.append(pos)
        velocity += Vector2(0, 980.0) * 0.12
        pos += velocity * 0.12

    trajectory.points = points
    trajectory.queue_redraw()

func _count_targets() -> int:
    var count := 0
    for block in get_tree().get_nodes_in_group("blocks"):
        if is_instance_valid(block):
            count += 1
    return count

func _all_targets_destroyed() -> bool:
    return _count_targets() == 0

func _update_ui() -> void:
    shot_label.text = "Shots: %d" % shot_count
    target_label.text = "Targets: %d" % _count_targets()

func _on_ball_body_entered(body: Node) -> void:
    if not is_instance_valid(body):
        return

    if body.is_in_group("blocks"):
        body.queue_free()
        _update_ui()

        if _all_targets_destroyed():
            _trigger_win()

func _trigger_win() -> void:
    if game_over:
        return

    game_over = true
    complete_label.text = "LEVEL COMPLETE!"
    complete_label.visible = true
    restart_button.visible = true
    main_menu_button.visible = true

    if is_instance_valid(ball):
        ball.freeze = true

    for block in get_tree().get_nodes_in_group("blocks"):
        if is_instance_valid(block):
            block.freeze = true

func _trigger_lose() -> void:
    if game_over:
        return

    game_over = true
    complete_label.text = "YOU LOSE!"
    complete_label.visible = true
    restart_button.visible = true
    main_menu_button.visible = true

    if is_instance_valid(ball):
        ball.freeze = true

    for block in get_tree().get_nodes_in_group("blocks"):
        if is_instance_valid(block):
            block.freeze = true

func _restart_level() -> void:
    get_tree().reload_current_scene()

func _on_restart_pressed() -> void:
    _restart_level()

func _on_main_menu_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
