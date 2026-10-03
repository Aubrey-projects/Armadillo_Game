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

func _physics_process(delta: float) -> void:
	# If the armadillo is above ground
	if front_left_ray.is_colliding() and front_right_ray.is_colliding() \
	and back_left_ray.is_colliding() and back_right_ray.is_colliding():
		
		# Gets the points the armadillo's legs hit the ground
		var front_left_hit = front_left_ray.get_collision_point()
		var front_right_hit = front_right_ray.get_collision_point()
		var back_left_hit = back_left_ray.get_collision_point()
		var back_right_hit = back_right_ray.get_collision_point()
		
		# Gets the normals of the ground below the armadillo's legs
		var front_left_hit_normal = front_left_ray.get_collision_normal()
		var front_right_hit_normal = front_right_ray.get_collision_normal()
		var back_left_hit_normal = back_left_ray.get_collision_normal()
		var back_right_hit_normal = front_left_ray.get_collision_normal()
		
		# Averages those normals
		var average_normal = (front_left_hit_normal + front_right_hit_normal \
		+ back_left_hit_normal + back_right_hit_normal).normalized()
		
		# Gets the desired orientation for the armadillo based upon the normals of the ground
		var target_basis = _basis_from_normal(average_normal)
		
		# Converts to quaternions
		var current_quaternion = transform.basis.orthonormalized().get_rotation_quaternion()
		var desired_quaternion = target_basis.get_rotation_quaternion()
		
		# Rotates the armadillo
		transform.basis = Basis(current_quaternion.slerp(desired_quaternion, ground_align_speed * delta))
		
		# Gets the average point of all four feet
		var average_point = (front_left_hit + front_right_hit \
		+ back_left_hit + back_right_hit) / 4.0
		
		# Gets the desired position for the armadillo and the height difference between that and the ground
		var target_position = average_point + average_normal * ground_offset
		var height_difference = average_normal.dot(target_position - global_position)
		
		# Moves the armadillo up from the slope of the ground
		position += average_normal * height_difference * ground_align_speed * delta
		
		# Rotates the CCDIK3D's target to match the ground's normal
		front_left_target.global_basis = _basis_from_normal(front_left_hit_normal)
		front_right_target.global_basis = _basis_from_normal(front_right_hit_normal)
		back_left_target.global_basis = _basis_from_normal(back_left_hit_normal)
		back_right_target.global_basis = _basis_from_normal(back_right_hit_normal)
		

# Function to switch the ground's normal to the basis for an object
func _basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	
	result.y = normal
	result.x = normal.cross(transform.basis.z)
	result.z = transform.basis.x.cross(normal)
	
	result = result.orthonormalized()
	
	return result
	
	
	
