extends Control
## In-game equipment screen. Opened by the equipment button (or the "equipment"
## action); pauses the game and shows three slots: Helmet, Sword, Ring. Only the
## helmet is functional so far — tap it to cycle through the helmets you own.
## Runs while paused (process_mode = Always, set in the scene).

const HELMET_ICON := {
	"bronze": preload("res://assets/textures/helmet_bronze.png"),
	"steel": preload("res://assets/textures/helmet_steel.png"),
	"gold": preload("res://assets/textures/helmet_gold.png"),
}
const SLOT_EMPTY := {
	"helmet": preload("res://assets/textures/equip_helmet.png"),
	"sword": preload("res://assets/textures/equip_sword.png"),
	"ring": preload("res://assets/textures/equip_ring.png"),
}
const HELMET_LABEL := {"": "None", "bronze": "Bronze", "steel": "Steel", "gold": "Gold"}

var _helmet_btn: Button
var _info: Label
var _close_btn: Button


func _ready() -> void:
	visible = false
	_build()
	GameManager.equipment_changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("equipment"):
		toggle()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		_refresh()
		_close_btn.grab_focus()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	for m in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + m, 8)
	panel.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	margin.add_child(vb)

	var title := Label.new()
	title.text = "EQUIPMENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	vb.add_child(title)

	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(slots)
	_helmet_btn = _make_slot(slots, "Helmet", "helmet", true)
	_make_slot(slots, "Sword", "sword", false)
	_make_slot(slots, "Ring", "ring", false)

	_info = Label.new()
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD
	_info.custom_minimum_size = Vector2(190, 0)
	_info.add_theme_font_size_override("font_size", 7)
	vb.add_child(_info)

	_close_btn = Button.new()
	_close_btn.text = "Close"
	_close_btn.add_theme_font_size_override("font_size", 10)
	_close_btn.pressed.connect(toggle)
	vb.add_child(_close_btn)


func _make_slot(parent: Node, label_text: String, key: String, interactive: bool) -> Button:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(box)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(48, 48)
	btn.expand_icon = true
	btn.icon = SLOT_EMPTY[key]
	if interactive:
		btn.pressed.connect(_cycle_helmet)
	else:
		btn.disabled = true
	box.add_child(btn)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 8)
	box.add_child(lbl)
	return btn


func _cycle_helmet() -> void:
	var options: Array = [""]
	options.append_array(GameManager.owned_helmets)
	var idx := options.find(GameManager.equipped_helmet)
	idx = (idx + 1) % options.size()
	GameManager.equip_helmet(options[idx])


func _refresh() -> void:
	var eq: String = GameManager.equipped_helmet
	_helmet_btn.icon = HELMET_ICON[eq] if eq != "" else SLOT_EMPTY["helmet"]
	if GameManager.owned_helmets.is_empty():
		_info.text = "Beat a boss without touching the ground to earn a helmet."
	elif eq == "":
		_info.text = "Helmet: None — tap to equip (owned: %s)" % ", ".join(GameManager.owned_helmets)
	else:
		var pct := int(round((1.0 - GameManager.HELMET_DAMAGE[eq]) * 100.0))
		_info.text = "%s helmet equipped — takes %d%% less damage." % [HELMET_LABEL[eq], pct]
