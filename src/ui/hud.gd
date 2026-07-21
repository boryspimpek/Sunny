extends CanvasLayer
## HUD: pasek życia, amunicja, przeładowanie, punkty.
## Zasilany wyłącznie sygnałami z EventBus - zero referencji do gracza.

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var reload_label: Label = $MarginContainer/VBoxContainer/ReloadLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel


func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.ammo_changed.connect(_on_ammo_changed)
	EventBus.reload_started.connect(_on_reload_started)
	EventBus.reload_finished.connect(_on_reload_finished)
	EventBus.score_changed.connect(_on_score_changed)
	reload_label.visible = false


func _on_health_changed(current: float, max_health: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = current


func _on_ammo_changed(current: int, magazine: int) -> void:
	ammo_label.text = "%d / %d" % [current, magazine]


func _on_reload_started(_duration: float) -> void:
	reload_label.visible = true


func _on_reload_finished() -> void:
	reload_label.visible = false


func _on_score_changed(score: int) -> void:
	score_label.text = "Punkty: %d" % score
