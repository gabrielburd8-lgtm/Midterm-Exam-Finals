extends RigidBody2D

func is_moving() -> bool:
    return linear_velocity.length() > 12.0 or abs(angular_velocity) > 0.08

func reset_motion() -> void:
    linear_velocity = Vector2.ZERO
    angular_velocity = 0.0
    sleeping = false
