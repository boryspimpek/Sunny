extends Node
## Globalna szyna sygnałów (autoload "EventBus").
## Odsprzęga HUD, audio i logikę punktacji od gameplayu.

# --- Gracz ---
signal player_health_changed(current: float, max_health: float)
signal player_died

# --- Broń / amunicja ---
signal weapon_changed(weapon: WeaponResource)
signal ammo_changed(current: int, magazine: int)
signal reload_started(duration: float)
signal reload_finished

# --- Wrogowie / punktacja ---
signal enemy_died(position: Vector3)
signal score_changed(score: int)

# --- Pickupy ---
signal pickup_collected(kind: StringName)

# --- Audio ---
signal sfx_requested(stream: AudioStream, position: Vector3)
