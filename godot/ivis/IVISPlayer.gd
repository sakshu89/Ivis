class_name IVISPlayer extends CharacterBody3D

@export var walk_speed := 4.5
@export var run_speed := 7.0
@export var acceleration := 18.0
@export var gravity := 18.0

@onready var camera: Camera3D = get_node("../CameraRig/Camera3D")
@onready var model_anchor: Node3D = $ModelAnchor

func _physics_process(delta: float) -> void:
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var mobile := get_node_or_null("../IVISHUD/Mobile/Joystick")
	if mobile and mobile.has_method("get_vector"):
		var mv: Vector2 = mobile.get_vector()
		if mv.length() > input_vec.length():
			input_vec = mv

	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	var direction := (right * input_vec.x + forward * -input_vec.y).normalized()

	var speed := run_speed if Input.is_action_pressed("run") else walk_speed
	var target := direction * speed
	velocity.x = move_toward(velocity.x, target.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target.z, acceleration * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = 7.0

	if direction.length_squared() > 0.01:
		var look := global_position + direction
		look_at(Vector3(look.x, global_position.y, look.z), Vector3.UP)

	move_and_slide()
