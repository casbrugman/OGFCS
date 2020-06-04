extends OptionButton

var paths = []

func _on_OptionButton_pressed():
	refresh()
		
func refresh():
	var prev = selected
	clear()
	paths = get_node("../../../").mode.get_maps()
	
	if paths is int:
		Game.print_error("Menu Start ERROR: Could not get gamemodes! code:%s" % paths)
		return
	
	for i in paths:
		add_item(i)
	if !prev > paths.size() - 1:
		select(prev)
	else:
		select(paths.size() - 1)
		
	emit_signal("item_selected", selected)
