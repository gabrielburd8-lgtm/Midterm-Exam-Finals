extends Node2D

@onready var ball: RigidBody2D = $Ball
@onready var trajectory: Node2D = $Trajectory
@onready var shot_label: Label = $UILayer/ShotsLabel
@onready var complete_label: Label = $UILayer/CompleteLabel
@onready var ball_spawn: Marker2D = $BallSpawn

var dragging := false
var shot_count := 0
var level_complete := false

func _ready() -> void:
    ball.position = ball_spawn.position
    ball.reset_motion()

    for target in get_tree().get_nodes_in_group("targets"):
        if is_instance_valid(target):
            target.body_entered.connect(_on_target_hit.bind(target))

    _update_ui()
    _update_trajectory()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        var mouse_pos = get_global_mouse_position()

        if event.pressed:
            if _can_drag_ball() and (ball.global_position - mouse_pos).length() < 90.0:
                dragging = true
        elif dragging:
            _launch_ball()

    if event is InputEventKey and event.pressed and event.keycode == KEY_R:
        _restart_level()

func _process(_delta: float) -> void:
    if dragging:
        _update_trajectory()

func _can_drag_ball() -> bool:
    if level_complete:
        return false
    return !ball.is_moving() and !dragging

func _launch_ball() -> void:
    if not dragging:
        return

    var pull = ball.global_position - get_global_mouse_position()
    if pull.length() < 12.0:
        dragging = false
        _update_trajectory()
        return

    var launch_velocity = pull * 4.6
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

    var velocity = drag * 4.6
    var pos = ball.global_position
    var points: PackedVector2Array = PackedVector2Array()

    for i in range(16):
        points.append(pos)
        velocity += Vector2(0, 980.0) * 0.12
        pos += velocity * 0.12

    trajectory.points = points
    trajectory.queue_redraw()

func _on_target_hit(body: Node, target: RigidBody2D) -> void:
    if body != ball:
        return

    if target.is_queued_for_deletion():
        return

    target.queue_free()
    _check_for_victory()

func _check_for_victory() -> void:
    for target in get_tree().get_nodes_in_group("targets"):
        if is_instance_valid(target) and not target.is_queued_for_deletion():
            return

    level_complete = true
    complete_label.visible = true

func _update_ui() -> void:
    shot_label.text = "Shots: %d" % shot_count

func _restart_level() -> void:
    get_tree().reload_current_scene()
