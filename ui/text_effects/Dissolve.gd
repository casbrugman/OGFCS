tool 
extends RichTextEffect

var bbcode = "dissolve"

func _process_custom_fx(char_fx):
	var start = char_fx.env.get("start", 0.0)
	var speed = char_fx.env.get("speed", 10.0)
	
	var alpha = 1
	
	if char_fx.elapsed_time > start:
		alpha -= (char_fx.elapsed_time - start) / speed

	char_fx.color.a = alpha
	return true;
