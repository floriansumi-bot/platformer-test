extends Area2D
## Wand projectile. Flies straight in `dir` (the way the knight faces) and kills
## any enemy it passes through, then frees itself after a short lifetime.
## Enemy bodies + their stomp Hurtbox are on layer 4; killing goes through the
## Hurtbox (the same path as a stomp), so it works for every enemy type.

var dir: Vector2 = Vector2.RIGHT
@export var speed: float = 240.0
@export var life: float = 1.4

var _hit: Dictionary = {}   # enemy instance ids already killed (pierce once each)


func _ready() -> void:
	collision_mask = 4
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_build_visual()


func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	_kill(body)


func _on_area_entered(a: Area2D) -> void:
	if a is Hurtbox:
		(a as Hurtbox).take_hit(100)
	elif a.owner != null:
		_kill(a.owner)


## Find the enemy's stomp Hurtbox and trigger it (kills any enemy type once).
func _kill(enemy: Node) -> void:
	if enemy == null:
		return
	var id := enemy.get_instance_id()
	if _hit.has(id):
		return
	for c in enemy.get_children():
		if c is Hurtbox:
			_hit[id] = true
			(c as Hurtbox).take_hit(100)
			return


func _build_visual() -> void:
	var glow := Polygon2D.new()
	glow.polygon = _disc(9.0)
	glow.color = Color(0.7, 0.4, 1.0, 0.45)
	add_child(glow)
	var core := Polygon2D.new()
	core.polygon = _disc(5.0)
	core.color = Color(0.85, 0.95, 1.0, 0.95)
	add_child(core)
	var t := create_tween().set_loops()
	t.tween_property(core, "scale", Vector2(1.3, 1.3), 0.18)
	t.tween_property(core, "scale", Vector2(1.0, 1.0), 0.18)


func _disc(r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts
