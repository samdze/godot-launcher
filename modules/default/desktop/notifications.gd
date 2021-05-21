extends Control

signal notification_show_request(notification)
signal notification_hide_request(notification)
signal notification_showing(notification)
signal notification_shown(notification)
signal notification_hiding(notification)
signal notification_hidden(notification)

class Notification extends Reference:
	var style : String
	var messsage : String

export(int) var hidden_y_position = 2
export(int) var shown_y_position = 28
export(int) var left_margin = 12
export(int) var right_margin = 12

var displaying = false
var notifications_queue : Array = []
var current_notification : Notification = null

onready var container : Container = $HBoxContainer
onready var panel : PanelContainer = $HBoxContainer/PanelContainer
onready var left_spacer : Control = $HBoxContainer/LeftSpace
onready var right_spacer : Control = $HBoxContainer/RightSpace
onready var label : Label = $HBoxContainer/PanelContainer/MarginContainer/Label
onready var tween : Tween = $Tween


func _ready():
	container.rect_position.y = hidden_y_position
	left_spacer.rect_min_size.x = left_margin
	right_spacer.rect_min_size.x = right_margin
	visible = false


func show_notification():
	current_notification = notifications_queue.pop_front() if notifications_queue.size() > 0 else null
	if current_notification != null:
		visible = true
		displaying = true
		panel.add_stylebox_override("panel", panel.get_stylebox(current_notification.style))
		label.text = current_notification.messsage
		tween.remove_all()
		tween.interpolate_property(container, "rect_position:y", container.rect_position.y, 28, 0.2)
		tween.interpolate_property(left_spacer, "rect_min_size:x", left_margin, 0, 0.15, 0, 2, 0.25)
		tween.interpolate_property(right_spacer, "rect_min_size:x", right_margin, 0, 0.15, 0, 2, 0.25)
		tween.interpolate_callback(self, 0.35, "_notification_shown", current_notification)
		
		tween.interpolate_callback(self, 3.35, "emit_signal", "notification_hide_request", current_notification)
		
		tween.start()
		emit_signal("notification_showing", current_notification)


func hide_notification():
	if current_notification != null:
		tween.remove_all()
		tween.interpolate_property(left_spacer, "rect_min_size:x", 0, left_margin, 0.15, 0, 2, 0)
		tween.interpolate_property(right_spacer, "rect_min_size:x", 0, right_margin, 0.15, 0, 2, 0)
		tween.interpolate_property(container, "rect_position:y", shown_y_position, hidden_y_position, 0.3, 0, 2, 0.2)
		tween.interpolate_callback(self, 0.5, "_notification_hidden", current_notification)
		
		tween.start()
		emit_signal("notification_hiding", current_notification)


func get_current_notification() -> Notification:
	return current_notification


func get_pending_notification() -> Array:
	return notifications_queue


func get_pending_notifications_count() -> int:
	return notifications_queue.size()


func append_notification(message : String, type : String):
	var style : String = "notification_message"
	match type:
		"warning":
			style = "notification_warning"
		"success":
			style = "notification_success"
		"error":
			style = "notification_error"
	
	var notif = Notification.new()
	notif.style = style
	notif.messsage = message
	
	notifications_queue.append(notif)
	_notify_queue()


func _notification_shown(notification : Notification):
	emit_signal("notification_shown", notification)


func _notification_hidden(notification : Notification):
	displaying = false
	visible = false
	current_notification = null
	emit_signal("notification_hidden", notification)
	_notify_queue()


func _notify_queue():
	if not displaying and notifications_queue.size() > 0:
		emit_signal("notification_show_request", notifications_queue.front())
