extends Window

signal spinbox_value_change
signal declare_exit_press
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _set_spinbox_max(max_num):
	$VBoxContainer/HBoxContainer/SpinBox.max_value = max_num

func _set_spinbox_value(value: int):
	$VBoxContainer/HBoxContainer/SpinBox.get_line_edit().set_text(str(value))
	$VBoxContainer/HBoxContainer/SpinBox.apply()

func _on_spin_box_value_changed(value: float) -> void:
	spinbox_value_change.emit(value)
	print(value)


func _on_button_pressed() -> void:
	$VBoxContainer/HBoxContainer/SpinBox.get_line_edit().set_text("0")
	$VBoxContainer/HBoxContainer/SpinBox.apply()


func _on_exit_button_pressed() -> void:
	declare_exit_press.emit()
