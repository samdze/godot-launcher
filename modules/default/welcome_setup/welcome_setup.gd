extends App

const step_viewer_panel = preload("step_viewer_panel.tscn")
const launcher_app = "default/launcher"

var steps = []
var current_step = 0

onready var welcome_view = $ConstraintContainer/WelcomeView
onready var configuration_view = $ConstraintContainer/Configuration

onready var input_mapping_step = $ConstraintContainer/Configuration/Steps/InputMapper

onready var step_panels_container = $ConstraintContainer/Configuration/StepIndex/StepPanelsContainer
onready var steps_indexer = $ConstraintContainer/Configuration/StepIndex
onready var step_highlighter = $ConstraintContainer/Configuration/StepIndex/StepHighlighter/Highlighter
onready var steps_container = $ConstraintContainer/Configuration/Steps

onready var tween = $Tween


func _ready():
	welcome_view.show()
	configuration_view.hide()
	
	welcome_view.connect("step_completed", self, "_welcome_passed")
	input_mapping_step.connect("step_completed", self, "_input_mapping_completed")
	for c in steps_container.get_children():
		c.connect("step_completed", self, "_step_completed", [c])
		
		var step_panel = step_viewer_panel.instance()
		step_panels_container.add_child(step_panel)
	connect("resized", self, "_resized", [], CONNECT_DEFERRED)


func _resized():
	propagate_notification(Container.NOTIFICATION_SORT_CHILDREN)
	step_highlighter.rect_position =  step_panels_container.get_child(current_step).rect_position
	step_highlighter.rect_size =  step_panels_container.get_child(current_step).rect_size


func _focus():
	emit_signal("window_mode_request", true)
	emit_signal("title_change_request", "")
	emit_signal("display_mode_request", Launcher.Mode.OPAQUE)
	
	for a in InputMap.get_actions():
		InputMap.action_erase_events(a)
	
	welcome_view.enable()


func _set_step(index, animate = true):
	current_step = index
	var i = 0
	configuration_view.notification(Container.NOTIFICATION_SORT_CHILDREN)
	steps_indexer.notification(Container.NOTIFICATION_SORT_CHILDREN)
	step_panels_container.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for c in steps_container.get_children():
		if i != index:
			c.disable()
		else:
			c.enable()
		i += 1
	if animate:
		tween.interpolate_property(step_highlighter, "rect_position", step_highlighter.rect_position, step_panels_container.get_child(index).rect_position, 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween.interpolate_property(step_highlighter, "rect_size", step_highlighter.rect_size, step_panels_container.get_child(index).rect_size, 0.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
		tween.start()
	else:
		step_highlighter.rect_position =  step_panels_container.get_child(index).rect_position
		step_highlighter.rect_size =  step_panels_container.get_child(index).rect_size


func _welcome_passed(succeeded):
	welcome_view.disable()
	configuration_view.enable()
	_set_step(0, false)


func _input_mapping_completed(succeeded):
	for action in input_mapping_step.mapping.keys():
		# Don't activate the home action at the moment.
		if action != "ui_home":
			InputMap.action_add_event(action, input_mapping_step.mapping[action])


func _step_completed(succeeded, step_node : Node):
	if succeeded:
		if step_node.get_index() == steps_container.get_child_count() - 1:
			# Setup completed
			call_deferred("_setup_completed")
		else:
			_set_step(step_node.get_index() + 1, true)
	else:
		_set_step(step_node.get_index() - 1, true)


func _setup_completed():
	for action in input_mapping_step.mapping.keys():
		Settings.set_value("system/input-" + action, input_mapping_step.mapping[action])
	# Finally add the home action mapping.
	InputMap.action_add_event("ui_home", input_mapping_step.mapping["ui_home"])
	
	Modules.reload()
	Settings.set_value("system/launcher_app", launcher_app)
	var launcher = Modules.get_loaded_component(launcher_app).resource.instance()
	System.get_launcher().app.add_app(launcher)
