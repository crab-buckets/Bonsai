extends Node2D

## Config
var growth_rate: float = 20.0 #default 20
var split_chance: float = 0.02
var max_children: int = 2
var energy_decay: float = 0.98
var min_energy: float = 0.05
var thickness_decay: float = 0.7

var light_direction:= Vector2(0, -1) #upward

## Tree state
var root: Branch
var all_branches := []

class Branch:
	"""
	Main class for branches off of main stem
	hold data for each branch
	
	"""
	var start_pos: Vector2
	var direction: Vector2
	var length: float = 10.0
	var thickness: float = 4.0
	var energy: float = 1.0
	var age: float = 0.0
	var children: Array = []
	var is_alive: bool = true
	
	func _init(start_pos, direction) -> void:
		self.start_pos = start_pos
		self.direction = direction.normalized()

func _ready():
	var screen_size = get_viewport_rect().size
	var start_pos = Vector2(screen_size.x /2, screen_size.y - 50)
	randomize()
	root = Branch.new(start_pos, Vector2(0, -1))
	root.thickness = 8.0
	root.length = 30.0
	all_branches.append(root)

func _physics_process(delta: float):
	grow_tree(delta)
	queue_redraw()

func grow_tree(delta):
	root.energy += 1.0 * delta
	for branch in all_branches:
		if not branch.is_alive:
			continue
		
		branch.age += delta
		
		#light influence
		var light_factor = max(branch.direction.dot(light_direction), 0.2)
		
		#growth length
		branch.length += growth_rate * branch.energy * light_factor * delta
		
		#energy decay
		branch.energy *= energy_decay
		
		#try to split
		if branch.children.size() < max_children and branch.energy > 0.2:
			if randf() < split_chance:
				split_branch(branch)
		
		#kill the weak
		if branch.energy < min_energy:
			branch.is_alive = false

func split_branch(parent: Branch):
	var angle_offset = deg_to_rad(randf_range(20, 40))
	
	#create two branches (dominant + secondary)
	
	var dir1 = parent.direction.rotated(angle_offset)
	var dir2 = parent.direction.rotated(-angle_offset * randf_range(0.5, 1.0))
	
	var start = parent.start_pos + parent.direction * parent.length
	
	var child1 = Branch.new(start, dir1)
	var child2 = Branch.new(start, dir2)
	
	child1.energy = parent.energy * 0.6
	child2.energy = parent.energy * 0.4
	
	#thickness taper
	child1.thickness = parent.thickness * thickness_decay
	child2.thickness = parent.thickness * thickness_decay
	
	parent.children.append(child1)
	parent.children.append(child2)
	
	all_branches.append(child1)
	all_branches.append(child2)

func _draw():
	draw_circle(Vector2(200, 200), 10, Color.RED)
	for branch in all_branches:
		if not branch.is_alive:
			continue
		
		var start = branch.start_pos
		var end = start + branch.direction * branch.length
		
		draw_line(start, end, Color.WHITE, branch.thickness)
		
		# Draw leaves on tips
		if branch.children.is_empty():
			draw_circle(end, 3.0, Color.WHITE)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		prune_at_position(event.position)

func prune_at_position(pos: Vector2):
	for branch in all_branches:
		var end = branch.start_pos + branch.direction * branch.length
		
		if end.distance_to(pos) < 10:
			branch.is_alive = false
			# Redistribute energy to parent-like behavior
			branch.energy = 0
