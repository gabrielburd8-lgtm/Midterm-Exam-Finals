extends Node2D

@onready var ball: RigidBody2D = $Ball
@onready var trajectory: Node2D = $Trajectory
@onready var shot_label: Label = $UI/ShotLabel
@onready var goal_label: Label = $UI/GoalLabel
@onready var result_label: Label = $UI/ResultLabel
@onready var restart_button: Button = $UI/RestartButton
@onready var main_menu_button: Button = $UI/MainMenuButton
@onready var ball_spawn: Marker2D = $BallSpawn
@onready var goal_area: Area2D = $GoalArea
@onready var special_orb: RigidBody2D = $SpecialOrb

var dragging := false
var shot_count := 0
var game_over := false
var result_state := ""

func _ready() -> void:
    ball.position = ball_spawn.position
    ball.reset_motion()
    ball.freeze = true

    restart_button.pressed.connect(_on_restart_pressed)
    main_menu_button.pressed.connect(_on_main_menu_pressed)
    goal_area.body_entered.connect(_on_goal_entered)

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

    if special_orb and special_orb.global_position.y > 900:
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

func _update_ui() -> void:
    shot_label.text = "Shots: %d" % shot_count
    goal_label.text = "Goal: Bring orb to the cup"

func _trigger_win() -> void:
    if game_over:
        return

    game_over = true
    result_state = "won"
    result_label.text = "YOU WON!"
    result_label.visible = true
    restart_button.visible = true
    main_menu_button.visible = true
    ball.freeze = true
    special_orb.freeze = true

    for block in get_tree().get_nodes_in_group("blocks"):
        if is_instance_valid(block):
            block.freeze = true

func _trigger_lose() -> void:
    if game_over:
        return

    game_over = true
    result_state = "lost"
    result_label.text = "YOU LOSE!"
    result_label.visible = true
    restart_button.visible = true
    main_menu_button.visible = true
    ball.freeze = true
    special_orb.freeze = true

    for block in get_tree().get_nodes_in_group("blocks"):
        if is_instance_valid(block):
            block.freeze = true

func _on_goal_entered(body: Node2D) -> void:
    if body == special_orb:
        _trigger_win()

func _restart_level() -> void:
    get_tree().reload_current_scene()

func _on_restart_pressed() -> void:
    _restart_level()

func _on_main_menu_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
