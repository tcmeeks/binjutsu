extends Node
class_name ColorSampler

## Utility for sampling pixel colors from sprites

static func sample_center_color(animated_sprite: AnimatedSprite2D) -> Color:
	"""Sample the center pixel color from an AnimatedSprite2D"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return Color.WHITE  # Default fallback color
	
	var current_animation = animated_sprite.animation
	var current_frame = animated_sprite.frame
	
	# Get the current frame texture
	var texture = animated_sprite.sprite_frames.get_frame_texture(current_animation, current_frame)
	if not texture:
		return Color.WHITE
	
	# Convert texture to image
	var image = texture.get_image()
	if not image:
		return Color.WHITE
	
	# Get center coordinates (integer division is intentional for pixel sampling)
	var center_x = image.get_width() / 2
	var center_y = image.get_height() / 2
	
	# Sample the center pixel
	var sampled_color = image.get_pixelv(Vector2i(center_x, center_y))
	
	# Return the sampled color (ensure it's not completely transparent)
	if sampled_color.a < 0.1:
		return Color.WHITE  # Fallback if center is transparent
	
	return sampled_color

static func sample_sprite2d_center_color(sprite: Sprite2D) -> Color:
	"""Sample the center pixel color from a regular Sprite2D"""
	if not sprite or not sprite.texture:
		return Color.WHITE
	
	var image = sprite.texture.get_image()
	if not image:
		return Color.WHITE
	
	# Integer division is intentional for pixel sampling  
	var center_x = image.get_width() / 2
	var center_y = image.get_height() / 2
	
	var sampled_color = image.get_pixelv(Vector2i(center_x, center_y))
	
	if sampled_color.a < 0.1:
		return Color.WHITE
	
	return sampled_color