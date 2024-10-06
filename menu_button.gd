extends MenuButton

var popup = get_popup()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(6):
		popup.add_item(str(i))
	
	popup.id_pressed.connect(_no_id_pressed)

func _no_id_pressed(id):
	text = popup.get_item_text(id)
