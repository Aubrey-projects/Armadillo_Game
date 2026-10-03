extends Node3D
class_name Armadillo

# Inspector variables
@export var ground_align_speed: float = 5.0
@export var ground_offset: float = 0.1

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
		"target": front_left_target
	},
	{
		"ray": front_right_ray,
		"target": front_right_target
	},
	{
		"ray": back_left_ray,
		"target": back_left_target
	},
	{
		"ray": back_right_ray,
		"target": back_right_target
	}
]

func _physics_process(delta: float) -> void:
	# If all legs are above a surface with a collision
	if front_left_ray.is_colliding() and front_right_ray.is_colliding() \
	and back_left_ray.is_colliding() and back_right_ray.is_colliding():
		
		# Defines placeholder variables
		var hit_points: Array[Vector3] = []
		var hit_normals: Array[Vector3] = []
		var average_normal: Vector3 = Vector3.ZERO
		var average_point: Vector3 = Vector3.ZERO
		
		for leg in legs:
			# Gets the ray and target of every leg
			var ray: RayCast3D = leg["ray"]
			var target: Marker3D = leg["target"]
			
			# Gets the hit point and normal of every ray and appends them to lists
			var hit_point: Vector3 = ray.get_collision_point()
			var hit_normal: Vector3 = ray.get_collision_normal()
			hit_points.append(hit_point)
			hit_normals.append(hit_normal)
			
			# Rotates the CCDIK3D's target to match the ground's normal
			target.global_basis = _basis_from_normal(hit_normal)
		
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

# Function to convert the ground's normal to the basis for an object
func _basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	
	result.y = normal
	result.x = normal.cross(transform.basis.z)
	result.z = transform.basis.x.cross(normal)
	
	result = result.orthonormalized()
	
	return result
	
	
	
