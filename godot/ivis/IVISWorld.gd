class_name IVISWorld extends Node3D

## IVIS is the playable layer built on top of the Reia codebase.
## It keeps the existing Reia systems intact while adding a mobile-first
## third-person world, adaptive rendering, photo mode, world switching,
## and persistent achievements.

@onready var player: CharacterBody3D = $Player
@onready var camera_rig: Node3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var hud: CanvasLayer = $IVISHUD
@onready var status_label: Label = $IVISHUD/TopBar/Status
@onready var world_label: Label = $IVISHUD/TopBar/World
@onready var photo_label: Label = $IVISHUD/PhotoMode
@onready var graphics_label: Label = $IVISHUD/TopBar/Graphics

var world_id: int = 0
var world_names := ["IVIS — Verdant Frontier", "IVIS — Jade Highlands", "IVIS — Ember Valley", "IVIS — Moonlit Ruins"]
var world_roots: Array[Node3D] = []
var photo_mode := false
var elapsed := 0.0
var fps_samples: Array[float] = []
var auto_quality := 1.0
var save_path := "user://ivis_save.json"
var achievements := {
	"first_step": false,
	"photo_mode": false,
	"world_hopper": false
}

func _ready() -> void:
	_setup_player_model()
	_build_worlds()
	_load_progress()
	_update_world_ui()
	_apply_mobile_defaults()
	$IVISHUD/Mobile/WorldNext.pressed.connect(_next_world)
	$IVISHUD/Mobile/Photo.pressed.connect(_toggle_photo_mode)
	$IVISHUD/Mobile/ZoomIn.pressed.connect(_zoom_in)
	$IVISHUD/Mobile/ZoomOut.pressed.connect(_zoom_out)
	$IVISHUD/Mobile/Achievement.pressed.connect(_show_achievement)
	$IVISHUD/Mobile/Exit.pressed.connect(_exit_to_title)
	photo_label.visible = false
	status_label.text = "IVIS ONLINE • Mobile runtime"
	achievements["first_step"] = true
	_save_progress()

func _process(delta: float) -> void:
	elapsed += delta
	var fps := Engine.get_frames_per_second()
	fps_samples.push_back(float(fps))
	if fps_samples.size() > 30:
		fps_samples.pop_front()
	if fps_samples.size() == 30:
		var avg := 0.0
		for sample in fps_samples:
			avg += sample
		avg /= fps_samples.size()
		_adapt_quality(avg)
	graphics_label.text = "AUTO • %d FPS • %d%% 3D" % [fps, int(auto_quality * 100.0)]
	_update_world_simulation(delta)

func _physics_process(_delta: float) -> void:
	if not photo_mode:
		_update_camera()

func _setup_player_model() -> void:
	var model_path := "res://client/assets/models/player/Reia.glb"
	var packed = load(model_path)
	if packed is PackedScene:
		var model := packed.instantiate()
		model.name = "ReiaModel"
		$Player/ModelAnchor.add_child(model)
		model.scale = Vector3.ONE
	else:
		# The repository contains the Git LFS pointer when the large binary
		# is not downloaded. Keep the game playable with a lightweight fallback.
		var mesh := CapsuleMesh.new()
		mesh.height = 1.8
		mesh.radius = 0.35
		var body := MeshInstance3D.new()
		body.mesh = mesh
		body.name = "IVISFallbackCharacter"
		$Player/ModelAnchor.add_child(body)

func _build_worlds() -> void:
	for i in range(4):
		var root := Node3D.new()
		root.name = "World_%d" % i
		add_child(root)
		world_roots.append(root)
		_generate_world(root, i)
		root.visible = i == world_id

func _generate_world(root: Node3D, id: int) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90.0, 90.0)
	ground.mesh = plane
	ground.position.y = -0.05
	var mat := StandardMaterial3D.new()
	mat.albedo_color = [Color("243b2a"), Color("28475a"), Color("4c2e24"), Color("252a45")][id]
	mat.roughness = 0.95
	ground.material_override = mat
	root.add_child(ground)

	var collision := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(90.0, 0.1, 90.0)
	shape.shape = box
	shape.position.y = -0.1
	collision.add_child(shape)
	root.add_child(collision)

	for x in range(-7, 8):
		for z in range(-7, 8):
			if ((x * 17 + z * 31 + id * 13) % 7) == 0:
				var pillar := MeshInstance3D.new()
				var mesh := CylinderMesh.new()
				mesh.top_radius = 0.4 + abs(z) * 0.01
				mesh.bottom_radius = 0.7
				mesh.height = 2.0 + float(abs(x + z)) * 0.18
				pillar.mesh = mesh
				pillar.position = Vector3(x * 4.5, mesh.height * 0.5, z * 4.5)
				pillar.material_override = mat
				root.add_child(pillar)

func _update_world_simulation(_delta: float) -> void:
	# Only the current world is visible/active. This is the first streaming
	# layer; heavier future worlds can be replaced by PackedScene streaming.
	for i in range(world_roots.size()):
		world_roots[i].process_mode = Node.PROCESS_MODE_INHERIT if i == world_id else Node.PROCESS_MODE_DISABLED

func _update_camera() -> void:
	var target := player.global_position + Vector3(0.0, 1.45, 0.0)
	camera_rig.global_position = camera_rig.global_position.lerp(target, 0.12)

func _adapt_quality(avg_fps: float) -> void:
	var target := 60.0
	if avg_fps < 28.0:
		auto_quality = max(0.60, auto_quality - 0.05)
	elif avg_fps < 40.0:
		auto_quality = max(0.70, auto_quality - 0.025)
	elif avg_fps > 58.0:
		auto_quality = min(1.0, auto_quality + 0.015)
	if is_instance_valid(get_viewport()):
		get_viewport().scaling_3d_scale = auto_quality
	if is_instance_valid($Sun):
		$Sun.directional_shadow_max_distance = lerp(45.0, 120.0, auto_quality)

func _apply_mobile_defaults() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().scaling_3d_scale = 1.0
	$Sun.directional_shadow_max_distance = 80.0

func _next_world() -> void:
	world_id = (world_id + 1) % world_roots.size()
	for i in range(world_roots.size()):
		world_roots[i].visible = i == world_id
		world_roots[i].process_mode = Node.PROCESS_MODE_INHERIT if i == world_id else Node.PROCESS_MODE_DISABLED
	_update_world_ui()
	achievements["world_hopper"] = true
	_save_progress()

func _update_world_ui() -> void:
	world_label.text = world_names[world_id]

func _toggle_photo_mode() -> void:
	photo_mode = not photo_mode
	photo_label.visible = photo_mode
	photo_label.text = "PHOTO MODE • FREEZE + FRAME YOUR SHOT"
	achievements["photo_mode"] = photo_mode or achievements["photo_mode"]
	$Player.set_physics_process(not photo_mode)
	_save_progress()

func _zoom_in() -> void:
	$CameraRig/SpringArm3D.spring_length = max(1.8, $CameraRig/SpringArm3D.spring_length - 0.8)

func _zoom_out() -> void:
	$CameraRig/SpringArm3D.spring_length = min(10.0, $CameraRig/SpringArm3D.spring_length + 0.8)

func _show_achievement() -> void:
	var unlocked := 0
	for key in achievements:
		if achievements[key]:
			unlocked += 1
	status_label.text = "ACHIEVEMENTS • %d/3 unlocked" % unlocked

func _save_progress() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"world": world_id, "achievements": achievements}))
		file.close()

func _load_progress() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data is Dictionary:
		world_id = clampi(int(data.get("world", 0)), 0, 3)
		var saved = data.get("achievements", {})
		if saved is Dictionary:
			for key in achievements:
				achievements[key] = bool(saved.get(key, false))

func _exit_to_title() -> void:
	get_tree().change_scene_to_file("res://client/ui/screens/menus/title_screen.tscn")
