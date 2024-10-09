extends Window

signal spinbox_value_change
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _set_spinbox_max(max_num):
	$HBoxContainer/SpinBox.max_value = max_num


func _on_spin_box_value_changed(value: float) -> void:
	spinbox_value_change.emit(value)
	print(value)


func _on_button_pressed() -> void:
	$HBoxContainer/SpinBox.get_line_edit().set_text("0")
	$HBoxContainer/SpinBox.apply()
