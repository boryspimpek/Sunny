extends Node3D


func _ready() -> void:
	_set_topmost()
	get_tree().create_timer(1.0).timeout.connect(_set_topmost)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_set_topmost()


func _set_topmost() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
