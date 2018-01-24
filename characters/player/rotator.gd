extends Node2D

var rot_speed = 0.03
var rotation = 0

func rotate_body(var body, r_input, align):
	r_input *= rot_speed
	rotation += r_input
	if !align:
		body.set_global_rot(rotation)
	else:
		align_to_axis(body)

func align_to_axis(var body):
	var r = body.get_global_rotd()
	if r < 0:
		r += 360
	var final_r = 0
	if r < 135 && r >= 45:
		final_r = PI / 2
	elif r < 225 && r >= 135:
		final_r = PI
	elif r < 315 && r >= 225:
		final_r = 3*PI/2
	rotation = final_r
	body.set_global_rot(rotation)