extends Control

var cutter_follow: bool
var mouse_position: Vector2
var start_cut_pos: Vector2
var end_cut_pos: Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if cutter_follow:
		$Cutter.position = mouse_position
		#print(mouse_position)

func _input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			$Label.text = "pressed"
			start_cut_pos = event.position - position
		if event.is_canceled():
			$Label.text = "canceled"
		mouse_position = event.position - position
	if event is InputEventMouseMotion:
		mouse_position = event.position - position



func _on_area_2d_mouse_entered() -> void:
	cutter_follow = true


func _on_area_2d_mouse_exited() -> void:
	cutter_follow = false
