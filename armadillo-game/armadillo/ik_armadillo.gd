extends Node3D
class_name Armadillo

# Inspector variables
@export var ground_align_speed: float = 5.0
@export var ground_offset: float = 0.1
@export var step_distance: float = 0.2
@export var movement_speed: float = 3.0
@export var rotation_speed: float = 10.0

# Ray references
@onready var front_left_ray: RayCast3D = $LegControllers/FrontLeft/GroundRay
@onready var front_right_ray: RayCast3D = $LegControllers/FrontRight/GroundRay
@onready var back_left_ray: RayCast3D = $LegControllers/BackLeft/GroundRay
@onready var back_right_ray: RayCast3D = $LegControllers/BackRight/GroundRay

# Target references
@onready var front_left_target: Marker3D = $LegControllers/FrontLeft/FrontLeftTarget
@onready var front_right_target: Marker3D = $LegControllers/FrontRight/FrontRightTarget
@onready var back_left_target: Marker3D = $LegControllers/BackLeft/BackLeftTarget
@onready var back_right_target: Marker3D = $LegControllers/BackRight/BackRightTarget

# Puts the variables of the legs into an array of dictionaries
@onready var legs: Array[Dictionary] = [
	{
		"ray": front_left_ray,
		"target": front_left_target,
		"planted_position": front_left_target.global_position,
		"needs_step": false,
		"is_stepping": false
	},
	{
		"ray": front_right_ray,
		"target": front_right_target,
		"planted_position": front_right_target.global_position,
		"needs_step": false,
		"is_stepping": false
	},
	{
		"ray": back_left_ray,
		"target": back_left_target,
		"planted_position": back_left_target.global_position,
		"needs_step": false,
		"is_stepping": false
	},
	{
		"ray": back_right_ray,
		"target": back_right_target,
		"planted_position": back_right_target.global_position,
		"needs_step": false,
		"is_stepping": false
	}
]

# Pairs the front left leg with the back right leg
# and the front right leg with the back left leg
var leg_pairs: Array[Array] = [
	[0, 3],
	[1, 2]
]
var active_pair: int = 0
var legs_finished: int = 0

func _physics_process(delta: float) -> void:
	# Moves the armadillo
	_handle_movement(delta)
	
	# If all legs are above a surface with a collision
	if front_left_ray.is_colliding() and front_right_ray.is_colliding() \
	and back_left_ray.is_colliding() and back_right_ray.is_colliding():
		
		# Defines placeholder variables
		var hit_points: Array[Vector3] = []
		var hit_normals: Array[Vector3] = []
		var average_normal: Vector3 = Vector3.ZERO
		var average_point: Vector3 = Vector3.ZERO
		
		for leg in legs:
			# Gets the ray, target, and planted position of every leg
			var ray: RayCast3D = leg["ray"]
			var target: Marker3D = leg["target"]
			var planted_position: Vector3 = leg["planted_position"]
			
			# Gets the hit point and normal of every ray and appends them to lists
			var hit_point: Vector3 = ray.get_collision_point()
			var hit_normal: Vector3 = ray.get_collision_normal()
			hit_points.append(hit_point)
			hit_normals.append(hit_normal)
			
			# Measures how far the ground has moved away from the planted foot
			var distance_to_target: float = planted_position.distance_to(hit_point)
			leg["needs_step"] = distance_to_target > step_distance
			
			# Rotates the CCDIK3D's target to match the ground's normal
			target.global_basis = _basis_from_normal(hit_normal)
		
		for leg_index in leg_pairs[active_pair]:
			var leg: Dictionary = legs[leg_index]
			
			if leg["needs_step"] and !leg["is_stepping"]:
				step_leg(leg)
		
		# Increments through the hit_normals list and gets the average
		for hit_normal in hit_normals:
			average_normal += hit_normal
		average_normal = average_normal.normalized()
		
		# Increments through the hit_points list and gets the average
		for hit_point in hit_points:
			average_point += hit_point
		average_point = average_point / hit_points.size()
		
		# Gets the desired orientation for the armadillo based upon the normals of the ground
		var target_basis = _basis_from_normal(average_normal)
		
		# Converts to quaternions
		var current_quaternion = transform.basis.orthonormalized().get_rotation_quaternion()
		var desired_quaternion = target_basis.get_rotation_quaternion()
		
		# Rotates the armadillo
		transform.basis = Basis(current_quaternion.slerp(desired_quaternion, ground_align_speed * delta))
		
		# Gets the desired position for the armadillo and the height difference between that and the ground
		var target_position = average_point + average_normal * ground_offset
		var height_difference = average_normal.dot(target_position - global_position)
		
		# Moves the armadillo up from the slope of the ground
		position += average_normal * height_difference * ground_align_speed * delta

# Function to move the armadillo
func _handle_movement(delta: float) -> void:
	var direction = Vector3.ZERO
	if Input.is_key_pressed(KEY_D):
		direction.z -= 1
	if Input.is_key_pressed(KEY_A):
		direction.z += 1
	if Input.is_key_pressed(KEY_W):
		direction.x -= 1
	if Input.is_key_pressed(KEY_S):
		direction.x += 1
	if direction.length() > 0:
		direction = direction.normalized()
		
	position += direction * movement_speed * delta

# Function to convert the ground's normal to the basis for an object
func _basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	
	result.y = normal
	result.x = normal.cross(transform.basis.z)
	result.z = transform.basis.x.cross(normal)
	
	result = result.orthonormalized()
	
	return result

# Function for the legs to step
func step_leg(leg: Dictionary) -> void:
	# Leg variables
	var ray: RayCast3D = leg["ray"]
	var target: Marker3D = leg["target"]
	var start_position: Vector3 = target.global_position
	var end_position: Vector3 = ray.get_collision_point()
	var middle_position: Vector3 = (start_position + end_position) / 2.0
	leg["is_stepping"] = true
	leg["needs_step"] = false
	
	# Step variables
	var step_height: float = 0.5
	var step_time: float = 0.2
	
	middle_position.y += step_height
	
	# Creating tween
	var tween: Tween = create_tween()
	
	# Starting animation
	tween.tween_property(
		target,
		"global_position",
		middle_position,
		step_time
	)
	
	# Ending animation
	tween.tween_property(
		target,
		"global_position",
		end_position,
		step_time
	)
	
	# Updating dictionary after the animation is done
	tween.tween_callback(finish_step.bind(leg, end_position))
	
# Function to update the leg after a step
func finish_step(leg: Dictionary, end_position: Vector3) -> void:
	leg["planted_position"] = end_position
	leg["is_stepping"] = false
	
	legs_finished += 1
	if legs_finished >= 2:
		legs_finished = 0
		
		if active_pair == 0:
			active_pair = 1
		else:
			active_pair = 0
