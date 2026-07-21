extends Node
## Globalny stan gry (autoload "GameState"): punkty, statystyki sesji.

var score: int = 0


func add_score(points: int) -> void:
	score += points
	EventBus.score_changed.emit(score)


func reset() -> void:
	score = 0
	EventBus.score_changed.emit(score)
