extends Control

@export_group("Operation Parameters")
## The speed of card dragging. When set to 0.0, dragging will have no effect. This value does not affect swipe rotation.
@export_range(0, 10, 0.01) var drag_speed_coefficient: float = 1.0
## The speed of card rotation. When set to 0.0, rotation will be disabled and only dragging will take effect.
@export_range(0, 1, 0.01) var rotation_speed_coefficient: float = 1.0
## The velocity decay applied during card rotation. A smaller value results in slower rotation decay.
## For a permanent spinning effect, set the range to 0.0 in the code. A value of 0.0 disables decay.
## To accelerate rotation, set the range to a negative value in the code. Not recommended, as it will spin infinitely.
@export_range(0, 10, 0.01) var rotation_velocity_decay: float = 10.0
## The speed of resetting to the initial position. When set to 0.0, resetting is disabled.
@export_range(0, 10, 0.01) var reset_speed: float = 5.0
## The minimum deviation threshold for resetting. When set to 0.0, it resets perfectly. 
## If set too small, the reset animation may appear jittery.
@export_range(0, 0.1, 0.001) var reset_min_threshold: float = 0.01
## Whether clicking a card moves it to the top position. When set to false, clicking will have no effect.
@export var click_move_to_top: bool = true
## The execution range (in radians) for the click-to-move-to-top action. 
## When set to 0.0, clicking will have no effect.
@export_range(0, PI, 0.01) var click_move_to_top_range: float = PI
## The rotation duration for the click-to-move-to-top action. This property works in conjunction 
## with the "rotation_speed_coefficient" property. When set to 0.0, the card will teleport to the position instantly.
@export_range(0, 5, 0.01) var click_move_to_top_duration: float = 1.0

@export_group("Ellipse Parameters")
## When set to true, the ellipse outline is visible. Precision depends on the "sample_count" property.
@export var show_ellipse_outline: bool = false
## The center position of the ellipse. Because it correlates with the "card_base_size" property, 
## there may be slight deviations. It is recommended to determine the card size before setting the ellipse position.
@export var ellipse_center: Vector2 = Vector2(0, 0)
## The length of the ellipse's X semi-axis. The longer of the two axes is the major axis. 
## If both are equal, the ellipse becomes a circle, and the axes represent the radius.
@export var x_semi_axis: float = 400.0
## The length of the ellipse's Y semi-axis. The longer of the two axes is the major axis. 
## If both are equal, the ellipse becomes a circle, and the axes represent the radius.
@export var y_semi_axis: float = 200.0
## This property only affects the rendering precision of the ellipse outline when "show_ellipse_outline" is true. 
## It does not affect the precision of card position calculations.
@export var sample_count: int = 300

@export_group("Card Parameters")
## Assigns a texture to each card. If the number of textures exceeds the "min_card_count", 
## the card count will increase. Values cannot be changed in the editor while the game is running; 
## changing them in the editor requires restarting the scene. Runtime script modifications are unaffected.
@export var card_texture_array: Array[Texture]
## The universal size for all cards. Changing this may affect the ellipse position. 
## It is recommended to determine the card size before setting the ellipse position.
@export var card_base_size: Vector2 = Vector2(50, 100)
## Cards not configured via the "card_texture_array" will use this default texture.
@export var default_card_texture: Texture
## Sets the number of cards on the ellipse. If this value is less than the size of "card_texture_array", 
## it will be overridden by the array size. If greater, extra cards will use the "default_card_texture".
## Note: The array size is supplemented at game start, preventing the card count from dropping below 
## the initial value. To reduce the count below the initial value in the editor, restart the scene. 
## Increasing the value in the editor works without restarting.
@export var min_card_count: int = 10
## Determines whether the top card is positioned at the bottom or top of the ellipse arc.
@export var bottom_arc_in_front: bool = true
## Moves cards around the top card further away or closer to it.
@export_range(-1, 1, 0.01) var step_offset_coefficient: float = 0.0
## Special property. May produce unusual effects when combined with "perspective_scale_coefficient". 
## For example, if this is 0.5 and "perspective_scale_coefficient" is 1.0.
@export_range(-1, 1, 0.01) var perspective_invert_subtract: float = 1.0
## Adds a perspective effect (near objects appear larger, far objects smaller). 
## Values < 0.0 invert the effect. Affected by the "bottom_arc_in_front" property.
@export_range(-1, 1, 0.01) var perspective_scale_coefficient: float = 0.0
## Determines whether the top card is affected by the "transparency_coefficient" property. 
## This also influences the overall effect of the transparency coefficient.
@export var top_card_transparent: bool = false
## The transparency coefficient based on each card's position on the ellipse. 
## When set to 0.0, all cards are fully opaque.
@export_range(-2.5, 2.5, 0.01) var transparency_coefficient: float = 0.0
## The rotation offset coefficient based on each card's position on the ellipse. 
## When set to 0.0, no additional rotation is applied.
@export_range(-1, 1, 0.01) var rotation_offset_coefficient: float = 0.0

# Runtime variables. Please do not modify arbitrarily.
var card_scene: TextureRect = TextureRect.new()
var card_array: Array = []
var mouse_down_position: Vector2
var is_mouse_position_recording: bool = false
var mouse_position: Vector2
var press_duration: int
var displacement_vector: Vector2 = Vector2.ZERO
var delta_offset: float 
var move_offset: float
var is_dragging: bool = false
var is_swiping: bool = false
var swipe_velocity: float = 0.0
var card_click_position: Vector2
var move_card_tween: Tween 

## Emit this signal to add a card texture. Provide the texture to add and its index position.
signal texture_array_add_texture(texture, index)
## Emit this signal to remove a card texture. Provide the texture to remove and the search start index. 
## Removes the first matching texture found.
signal texture_array_remove_texture(texture, start_index)
## Emitted when the top card position is clicked. Provides the clicked card.
signal top_card_clicked(card)

func _ready():
	texture_array_add_texture.connect(add_texture_to_array)
	texture_array_remove_texture.connect(remove_texture_from_array)
	initialize_ellipse_and_cards()

func _process(delta):
	update_card_count()
	process_card_states(delta)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if is_swiping:
		return
	if event is InputEventMouse:
		mouse_position = event.position
		
	var center_to_mouse_vec = get_center_to_mouse_vector()
	var center_to_mouse_len = center_to_mouse_vec.length()
	var ellipse_point_len = (get_point_on_ellipse(get_radian_from_point(center_to_mouse_vec + ellipse_center) + PI / 2) - ellipse_center).length()
	var dead_zone_distance = min(ellipse_point_len - ellipse_point_len * 0.3, ellipse_point_len - 100)

	if center_to_mouse_len <= dead_zone_distance:
		is_mouse_position_recording = false
		delta_offset = move_offset
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var press_time: int
		if event.pressed:
			is_dragging = true
			swipe_velocity = 0
			is_mouse_position_recording = false
			delta_offset = move_offset
			displacement_vector = Vector2.ZERO
			press_time = Time.get_ticks_msec()
			press_duration = press_time
		else:
			is_dragging = false
			delta_offset = move_offset
			press_duration = Time.get_ticks_msec() - press_duration	
			swipe_velocity = displacement_vector.length() / press_duration
			is_swiping = true
	elif event is InputEventMouseMotion and is_dragging and center_to_mouse_len > dead_zone_distance:
		if not is_mouse_position_recording:
			mouse_down_position = event.position
			is_mouse_position_recording = true
		var rotation_radian = get_radian_from_point(event.position) - get_radian_from_point(mouse_down_position)
		displacement_vector = event.position - mouse_down_position
		drag_cards(rotation_radian)

func initialize_ellipse_and_cards():
	ellipse_center = self.global_position
	self.global_position = Vector2.ZERO
	ellipse_center -= get_ellipse_offset_correction()
	for i in range(min_card_count):
		if card_texture_array.size() < min_card_count:
			texture_array_add_texture.emit()

func update_card_count():
	if card_texture_array.size() >= min_card_count:
		min_card_count = card_texture_array.size()
	if card_array.size() < min_card_count:
		add_cards()
	if card_array.size() > min_card_count:
		remove_cards()

func process_card_states(delta):
	for card in card_array:
		update_card_transparency(card)
		update_card_size(card)
		update_z_index(card)
		update_card_rotation(card)
	update_card_positions()
	recover_offset(delta)
	if not is_dragging and is_swiping:
		swipe_cards(delta)

func drag_cards(rotation_radian: float):
	if drag_speed_coefficient == 0:
		return
	move_offset = delta_offset - rotation_radian * drag_speed_coefficient
	if move_card_tween != null and move_card_tween.is_valid():
		print("Interrupting tween animation while dragging")
		move_card_tween.kill()

func swipe_cards(delta: float):
	swipe_velocity = max(swipe_velocity - rotation_velocity_decay * delta, 0)
	if swipe_velocity == 0:
		is_swiping = false
		
	var up_neg_down_pos = abs(mouse_down_position.y - ellipse_center.y) / (mouse_down_position.y - ellipse_center.y)
	var left_neg_right_pos = abs(mouse_down_position.x - ellipse_center.x) / (mouse_down_position.x - ellipse_center.x)
	var selected_direction
	var normalized_direction
	
	if abs(displacement_vector.x) > abs(displacement_vector.y):
		selected_direction = displacement_vector.normalized().x
		normalized_direction = up_neg_down_pos * selected_direction
	else:
		selected_direction = displacement_vector.normalized().y
		normalized_direction = -(left_neg_right_pos * selected_direction)
		
	move_offset += rotation_speed_coefficient * swipe_velocity * PI * normalized_direction * delta 

func recover_offset(delta: float):
	if swipe_velocity >= reset_speed or is_dragging:
		return
	var required_correction = get_min_offset_to_target()
	if abs(required_correction) <= reset_min_threshold:
		required_correction = 0
	move_offset += required_correction * reset_speed * delta

func update_card_positions():
	if min_card_count <= 0:
		return
	var base_step = 2 * PI / min_card_count
	var count: int = 0
	for card in card_array:
		var step_amount = count * base_step - move_offset
		count += 1
		var corrected_step = correct_card_step(step_amount)
		var card_pos = get_point_on_ellipse(corrected_step)
		card.position = card_pos 	

func correct_card_step(base_step: float) -> float:
	var correction_factor = sin(base_step) * step_offset_coefficient
	var corrected_step = base_step + correction_factor
	return corrected_step

func get_corrected_step_from_base(base_step: float) -> float:
	var pre_correction_step = base_step
	var max_iterations: int = 50
	var precision: float = 1e-6
	for i in range(max_iterations):
		var func_value = step_offset_coefficient * sin(pre_correction_step) + pre_correction_step - base_step
		var func_derivative = 1.0 + step_offset_coefficient * cos(pre_correction_step)
		var increment = func_value / func_derivative
		pre_correction_step -= increment
		if abs(increment) < precision:
			return pre_correction_step
	return pre_correction_step
	
func update_card_size(card: TextureRect):
	card.size = card_base_size
	card.pivot_offset = card.size / 2
	var final_scale = Vector2(1, 1) * (perspective_invert_subtract - calculate_perspective_scale(get_radian_from_point(card.position)))
	card.scale = final_scale

func calculate_perspective_scale(step: float) -> float:
	var scale_factor: float
	if bottom_arc_in_front:
		scale_factor = (cos(step + PI / 2) + 1) / 2 * perspective_scale_coefficient
	else:
		scale_factor = (cos(step - PI / 2) + 1) / 2 * perspective_scale_coefficient
	return scale_factor

func update_card_transparency(card: TextureRect):
	var alpha = 1 - calculate_transparency(get_radian_from_point(card.position))
	card.modulate.a = alpha

func calculate_transparency(step: float) -> float:
	if transparency_coefficient > 0:
		var alpha_factor = (cos(step + PI / 2) + 1 + int(top_card_transparent) * transparency_coefficient) / 2 * transparency_coefficient
		return alpha_factor
	if transparency_coefficient < 0:
		var alpha_factor = (cos(step - PI / 2) + 1 - int(top_card_transparent) * transparency_coefficient) / 2 * -transparency_coefficient 
		return alpha_factor
	return 0.0

func update_card_rotation(card: TextureRect):
	var corresponding_radian = get_radian_from_point(card.position)
	var calculation = cos(corresponding_radian) * PI * rotation_offset_coefficient
	card.rotation = calculation

func update_z_index(card: TextureRect):
	var z_index_value = calculate_z_index(get_radian_from_point(card.position))
	card.z_index = int(z_index_value)

func calculate_z_index(step: float) -> float:
	var index: float
	if bottom_arc_in_front:
		index = abs((cos(step + PI / 2) - 1) / 2) * 100
	else:
		index = (cos(step + PI / 2) + 1) / 2 * 100
	return index

func add_cards():
	var card_instance = card_scene.duplicate() as TextureRect
	card_instance.expand_mode = 1
	card_instance.texture = default_card_texture
	card_instance.size = card_base_size
	add_child(card_instance)
	card_array.append(card_instance)
	card_instance.gui_input.connect(handle_card_input.bind(card_instance))
	replace_card_textures()

func remove_cards():
	var card_instance = card_array.pop_back()
	remove_child(card_instance)
	card_instance.queue_free()
	replace_card_textures()

func replace_card_textures():
	for i in range(card_array.size()):
		card_array[i].texture = card_texture_array[i] if i < card_texture_array.size() else default_card_texture

func add_texture_to_array(texture: Texture = null, index: int = -1):
	if texture == null:
		texture = default_card_texture
	if index == -1 or index >= card_texture_array.size():
		card_texture_array.append(texture)
		return
	card_texture_array.insert(index, texture)

func remove_texture_from_array(texture: Texture, start_index: int = 0):
	var idx = card_texture_array.find(texture, start_index)
	if idx != -1:
		card_texture_array.remove_at(idx)
		min_card_count = card_texture_array.size()

func get_center_to_mouse_vector() -> Vector2:
	var mouse_vec = mouse_position - ellipse_center 
	var correction = mouse_vec - get_ellipse_offset_correction()
	return correction

func get_point_on_ellipse(angle: float) -> Vector2:
	var x = ellipse_center.x + x_semi_axis * cos(angle - PI / 2 + PI * int(bottom_arc_in_front))
	var y = ellipse_center.y + y_semi_axis * sin(angle - PI / 2 + PI * int(bottom_arc_in_front))
	return Vector2(x, y)

func get_radian_from_point(point: Vector2) -> float:
	var dx = point.x - ellipse_center.x
	var dy = point.y - ellipse_center.y
	var radian = atan2(dy / y_semi_axis, dx / x_semi_axis) 
	return radian

func get_min_offset_to_target() -> float:
	var target_radian = PI * int(bottom_arc_in_front) - PI / 2
	var min_length: float = INF
	var min_offset: float = INF
	for card in card_array:
		var pos = card.position
		var corresponding_radian = get_radian_from_point(pos)
		var length = abs(corresponding_radian - target_radian)
		min_length = min(length, min_length)
		if min_length == length:
			min_offset = corresponding_radian - target_radian
	return min_offset

func handle_card_input(event: InputEvent, card: TextureRect) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			card_click_position = card.position
		else:
			if card.position == card_click_position:
				if is_card_at_top_position(card):
					top_card_clicked.emit(card)
				elif click_move_to_top:
					move_card_to_top(card)

func is_card_at_top_position(card: TextureRect) -> bool:
	var corresponding_radian = get_radian_from_point(card.position) + PI / 2 - PI * int(bottom_arc_in_front)
	if get_min_offset_to_target() == corresponding_radian:
		return true
	return false

func move_card_to_top(card: TextureRect):
	var corresponding_radian = get_radian_from_point(card.position)
	var target_radian = PI * int(bottom_arc_in_front) - PI / 2
	var required_move_offset = corresponding_radian - target_radian
	if abs(required_move_offset) >= click_move_to_top_range:
		return
	move_card_tween = create_tween()
	move_card_tween.set_trans(Tween.TRANS_BACK)
	move_card_tween.set_ease(Tween.EASE_OUT)
	var pre_correction_offset = get_corrected_step_from_base(required_move_offset)
	move_card_tween.tween_property(self, "move_offset", move_offset + pre_correction_offset, click_move_to_top_duration)

func get_ellipse_offset_correction() -> Vector2:
	return card_base_size / 2

func _draw() -> void:
	if not show_ellipse_outline:
		return
	var step = 2 * PI / sample_count
	var point_list = []
	for i in range(sample_count + 1):
		var angle = i * step
		var point = get_point_on_ellipse(angle) + get_ellipse_offset_correction()
		point_list.append(point)
	for i in range(point_list.size() - 1):
		draw_line(point_list[i], point_list[i + 1], Color(1, 0, 0), 2)