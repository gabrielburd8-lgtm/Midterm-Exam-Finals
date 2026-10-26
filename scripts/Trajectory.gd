extends Node2D

@export var color: Color = Color(0.4, 0.46, 0.85, 0.8)
var points: PackedVector2Array = PackedVector2Array()

func _draw() -> void:
    if points.is_empty():
        return

    for point in points:
        draw_circle(point, 3.0, color)
