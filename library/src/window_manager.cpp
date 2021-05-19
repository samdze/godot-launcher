#ifdef LINUX
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/XKBlib.h>
#include <limits.h>
#endif

#include <OS.hpp>
#include <InputMap.hpp>
#include <InputEventKey.hpp>

#include "window_manager.h"


WindowManager::WindowManager() {
	
}

int WindowManager::on_x_error(Display* display, XErrorEvent* e) {
#ifdef LINUX
	fprintf(stderr, "[WM] X error code %u detected\n", e->error_code);
	fflush(stdout);
	fflush(stderr);
#endif
	return 0;
}

int WindowManager::on_wm_detected(Display* display, XErrorEvent* e) {
#ifdef LINUX
	// In the case of an already running window manager, the error code from
   // XSelectInput is BadAccess. We don't expect this handler to receive any
   // other errors.
   if (e->error_code == BadAccess) {
   	wm_detected = true;
   } else {
   	fprintf(stderr, "[WM] Unexpected error during window manager detection\n");
   	exit(EXIT_FAILURE);
   }
#endif
   return 0;
}

void WindowManager::purge_window(Window w) {
#ifdef LINUX
	uint64_t searching_window = (uint64_t)w;
	// Also remove the window itself? At the bebinning or at the end?
	// Removing it at the beginning at the moment
	printf("[WM] Trying to purge window %ld\n", w);
	stack_remove_window(w);
	while (windows_parents.has(searching_window)) {
		uint64_t child = searching_window;
		uint64_t parent = windows_parents[child];

		stack_remove_window(parent);
		printf("[WM] - Parent found, removed window %ld\n", parent);

		searching_window = parent;
		windows_parents.erase(child);
	}
#endif
}

void WindowManager::print_class_and_name(Window w) {
#ifdef LINUX
	XClassHint ch;
   if(XGetClassHint(display, w, &ch)) {
      printf("[WM] - Printing window %ld properties (name, class): %s, %s\n", w, ch.res_name, ch.res_class);
   } else {
      printf("[WM] - Couldn't print properties for window %ld\n", w);
   }
#endif
}

Window WindowManager::get_window_id_from_pid(unsigned long pid) {
#ifdef LINUX
	atom_pid = XInternAtom(display, "_NET_WM_PID", True);
	if(atom_pid == None) {
		printf("[WM] _NET_WM_PID not found.");
		return 0;
	}
#endif
	return search_window_for_pid(root, pid);
}

Window WindowManager::search_window_for_pid(Window w, unsigned long pid) {
#ifdef LINUX
	// Get the PID for the current Window.
	Atom				type;
	int				format;
	unsigned long	n_items;
	unsigned long	bytes_after;
	unsigned char	*prop_pid = 0;
	if(Success == XGetWindowProperty(display, w, atom_pid, 0, 1, False, XA_CARDINAL,
												&type, &format, &n_items, &bytes_after, &prop_pid)) {
		if(prop_pid != 0) {
			// If the PID matches, add this window to the result set.
			if(pid == *((unsigned long *)prop_pid)) {
				XFree(prop_pid);
				return w;
			}
			XFree(prop_pid);
		}
	}

	// Recurse into child windows.
	Window		w_root;
	Window		w_parent;
	Window		*w_child;
	unsigned		n_children;
	if(0 != XQueryTree(display, w, &w_root, &w_parent, &w_child, &n_children)) {
		Window searching_w = 0;
		for(unsigned i = 0; i < n_children; i++) {
			searching_w = search_window_for_pid(w_child[i], pid);
			if (searching_w != 0) {
				return searching_w;
			}
		}
	}
#endif
	return 0;
}

void WindowManager::_init() {
	thread = Ref<Thread>(Thread::_new());
	mutex = Ref<Mutex>(Mutex::_new());
}

void WindowManager::_ready() {
#ifdef LINUX
	if(!(display = XOpenDisplay(0x0))) {
		fprintf(stderr, "[WM] Failed to open X display\n");
		return;
	}

	atom_supported = XInternAtom(display, "_NET_SUPPORTED", False);
	atom_active_window = XInternAtom(display, "_NET_ACTIVE_WINDOW", False);
	atom_net_name = XInternAtom(display, "_NET_WM_NAME", False);
	atom_name = XInternAtom(display, "WM_NAME", False);

	root = DefaultRootWindow(display);
	printf("[WM] Root is %ld\n", root);

	// Check if another window manager is running
	wm_detected = false;
	XSetErrorHandler(&on_wm_detected);
	XSelectInput(
		display,
		root,
		SubstructureRedirectMask | SubstructureNotifyMask);
	XSync(display, False);
	if (wm_detected) {
		fprintf(stderr, "[WM] Detected another window manager on display %s\n", XDisplayString(display));
		return;
	}
	XSetErrorHandler(&on_x_error);

	// Configure window manager to support the _NET_ACTIVE_WINDOW (EWMH) hint
	XChangeProperty(display, root, atom_supported, XA_ATOM, 32,
		PropModeReplace, (unsigned char *) &atom_active_window, 1);
	
	launcher = get_window_id_from_pid(OS::get_singleton()->get_process_id());
	/*XSelectInput(
		display,
		launcher,
		VisibilityChangeMask);*/

	Godot::print(String("[WM] Window id of Godot launcher is ") + Variant((uint64_t)launcher));
#endif
}

void WindowManager::stack_add_window(Window w) {
#ifdef LINUX
	if (w == root) {
		printf("[WM] - Window is root, aborting\n");
		return;
	}
	//XMapRaised(display, w);
	XMapWindow(display, w);
	//XSetInputFocus(display, w, RevertToPointerRoot, CurrentTime);
	raise_window(w);
	XChangeProperty(display, root, atom_active_window,
		XA_WINDOW, 32, PropModeReplace, (unsigned char *) &(w), 1);

	Window prev_window = windows_stack.size() > 0 ? windows_stack.back() : 0;
	bool already_mapped = stack_has_window(w);
	if(already_mapped) {
		// Removing the window from the stack first
		for (auto it = windows_stack.begin(); it != windows_stack.end();) {
			if (*it == w) {
				it = windows_stack.erase(it);
			} else {
				++it;
			}
		}
	} else {
		XSelectInput(display, w, PropertyChangeMask);
	}

	//printf("- Stack size before adding: %d\n", windows_stack.size());
	windows_stack.push_back(w);
	names_add_window(w);
	//printf("- Stack size after adding: %d\n", windows_stack.size());
	//printf("- Added %ld to stack and raised it. Resulting stack:", w);
	for (auto it = windows_stack.begin(); it != windows_stack.end();) {
		//printf(" %ld;", *it);
		++it;
	}
	printf("\n");

	//print_class_and_name(w);
	if(!already_mapped) {
		call_deferred("emit_signal", "window_mapped", (uint64_t)w);
	}
	if (prev_window != (windows_stack.size() > 0 ? windows_stack.back() : 0)) {
		input_focus = (windows_stack.size() > 0 ? windows_stack.back() : 0);
		call_deferred("emit_signal", "active_window_changed", (uint64_t)input_focus);
	}
	fflush(stdout);
	fflush(stderr);
#endif
}

void WindowManager::stack_remove_window(Window w) {
#ifdef LINUX
	if (windows_stack.size() == 0) {
		printf("[WM] - Stack is already empty, aborting\n");
		return;
	}

	Window current = windows_stack.back();
	// Removing the window from the stack
	//printf("- Removing %ld. Resulting stack:", w);
	bool removed = false;
	for (auto it = windows_stack.begin(); it != windows_stack.end();) {
		if (*it == w) {
			it = windows_stack.erase(it);
			removed = true;
		} else {
			//printf(" %ld;", *it);
			++it;
		}
	}
	printf("\n");
	names_remove_window(w);
	if (removed) {
		call_deferred("emit_signal", "window_unmapped", (uint64_t)w);
	}

	// Selecting and focusing the top window
	if (windows_stack.size() > 0 && current != windows_stack.back()) {
		Window top = windows_stack.back();

		//XSetInputFocus(display, top, RevertToPointerRoot, CurrentTime);
		raise_window(top);
		//XRaiseWindow(display, top);
		XChangeProperty(display, root, atom_active_window,
			XA_WINDOW, 32, PropModeReplace, (unsigned char *) &(top), 1);
		//printf("- Mapped and gave input focus to %ld\n", top);
	} else if(windows_stack.size() == 0) {
		//printf("- No other windows are mapped in the stack\n");
	} else if(current == windows_stack.back()) {
		//printf("- The top window %ld in the stack is already the active one\n", windows_stack.back());
	}
	if (current != (windows_stack.size() > 0 ? windows_stack.back() : 0)) {
		input_focus = (windows_stack.size() > 0 ? windows_stack.back() : 0);
		call_deferred("emit_signal", "active_window_changed", (uint64_t)input_focus);
	}
#endif
}

void WindowManager::stack_raise_window(Window w) {
#ifdef LINUX
	//printf("- Raising window %ld on top of the stack\n", w);
	if (windows_stack.size() == 0) {
		printf("[WM] - The stack is empty, aborting\n");
		return;
	}

	bool window_found = false;
	for (auto it = windows_stack.begin(); it != windows_stack.end();) {
		if (*it == w) {
			window_found = true;
			it = windows_stack.erase(it);
			break;
		} else {
			++it;
		}
	}
	if (!window_found) {
		printf("[WM] - Window not found in the stack, aborting\n");
		return;
	}

	windows_stack.push_back(w);
	//printf("- Window %ld is now the top one. Resulting stack:", w);
	for (auto it = windows_stack.begin(); it != windows_stack.end();) {
		//printf(" %ld;", *it);
		++it;
	}
	printf("\n");

	//print_class_and_name(w);
#endif
}

bool WindowManager::stack_has_window(Window w) {
	if (windows_stack.size() == 0)
		return false;

	bool window_found = false;
#ifdef LINUX
	for (auto it = windows_stack.begin(); it != windows_stack.end();) {
		if (*it == w) {
			window_found = true;
			break;
		} else {
			++it;
		}
	}
#endif
	return window_found;
}

void WindowManager::names_add_window(Window w) {
#ifdef LINUX
	char* c_name = NULL;
	String previous;
	bool has_name = false;
	if (windows_names.has((uint64_t)w)) {
		previous = windows_names[(uint64_t)w];
		has_name = true;
	}
	String title;
	if (XFetchName(display, w, &c_name)) {
		title = String(c_name);
		XFree(c_name);
	}
	if (title.empty()) {
		XClassHint ch;
		if(XGetClassHint(display, w, &ch)) {
			title = String(ch.res_name);
			if (title.empty()) {
				title = String(ch.res_class);
			}
			XFree(ch.res_class);
			XFree(ch.res_name);
		}
	}
	if (!has_name || previous != title) {
		windows_names[(uint64_t)w] = title;
		Godot::print("[WM] Updating window title to " + title);
		call_deferred("emit_signal", "window_name_changed", (uint64_t)w, title);
	}
	/*XClassHint ch;
   if(XGetClassHint(display, w, &ch)) {
      //printf("- Printing window %ld properties (name, class): %s, %s\n", w, ch.res_name, ch.res_class);
		String title = String(ch.res_name);
		windows_titles[(uint64_t)w] = title;
		//Godot::print(String("Title of window ") + Variant(window_id) + " is: " + title);
   }*/
#endif
}

void WindowManager::names_remove_window(Window w) {
#ifdef LINUX
	if (windows_names.has((uint64_t)w)) {
		windows_names.erase((uint64_t)w);
	}
#endif
}

void WindowManager::activate_window(uint64_t window_id) {
#ifdef LINUX
	mutex->lock();

	if (stack_has_window(window_id)) {
		stack_add_window(window_id);
	}

	mutex->unlock();
#endif
}

void WindowManager::raise_window(uint64_t window_id) {
#ifdef LINUX
	/*uint64_t raising_window = window_id;
	Godot::print(String("[WM GODOT] Window raise ") + Variant(window_id));*/
	XRaiseWindow(display, window_id);
	/*printf("[WM] Raising window %ld\n", raising_window);
	Godot::print(String("[WM GODOT] Window raise ") + Variant(window_id));
	printf("[WM] Raising window %ld\n", raising_window);
	Godot::print(String("[WM GODOT] Window raise ") + Variant(window_id));
	printf("[WM] Raising window %ld\n", raising_window);
	Godot::print(String("[WM GODOT] Window raise ") + Variant(window_id));
	printf("[WM] Raising window %ld\n", raising_window);
	Godot::print(String("[WM GODOT] Window raise ") + Variant(window_id));
	printf("[WM] Raising window %ld\n", raising_window);
	Godot::print(String("[WM GODOT] Window raise ") + Variant(window_id));*/
	/*if ((Window)window_id == top_window) {
		//XSetInputFocus(display, top_window, RevertToPointerRoot, CurrentTime);
	}*/
	/*printf("[WM] Testing this raised window against the always on top window %ld\n", top_window);
	if (top_window > 0L) {
		printf("[WM] %ld is greater than 0L\n", top_window);
	}
	if (top_window != raising_window) {
		printf("[WM] The raised window being tested (!=) against the top one is %ld\n", raising_window);
		printf("[WM] %ld is not equal to %ld\n", top_window, raising_window);
	} else {
		printf("[WM] The raised window being tested (==) against the top one is %ld\n", raising_window);
		printf("[WM] %ld is equal to %ld\n", top_window, raising_window);
	}*/
	if (top_window > 0L && top_window != window_id) {
		//XSetInputFocus(display, top_window, RevertToPointerRoot, CurrentTime);
		XRaiseWindow(display, top_window);
		//printf("[WM] Raising the always on top window %ld\n", top_window);
	}
	/*printf("[WM] Raising the always on top window %ld in any case...\n", top_window);
	XRaiseWindow(display, top_window);
	fflush(stdout);
	fflush(stderr);*/
#endif
}

void WindowManager::lower_window(uint64_t window_id) {
#ifdef LINUX
	//XLowerWindow(display, (Window)(window_id.operator unsigned int()));
	XLowerWindow(display, window_id);
#endif
}

void WindowManager::kill_window(uint64_t window_id) {
#ifdef LINUX
	mutex->lock();
	purge_window(window_id);
	mutex->unlock();

	XKillClient(display, window_id);
#endif
}

void WindowManager::give_focus(uint64_t window_id, bool force = false) {
#ifdef LINUX
	mutex->lock();
	input_focus = window_id;
	mutex->unlock();
	if (force) {
		//XSetInputFocus(display, (Window)window_id, RevertToPointerRoot, CurrentTime);
	}
#endif
}

void WindowManager::give_focus_to_active(bool force = false) {
#ifdef LINUX
	mutex->lock();
	input_focus = windows_stack.size() > 0 ? windows_stack.back() : 0L;
	mutex->unlock();

	if (input_focus > 0 && force) {
		//XSetInputFocus(display, input_focus, RevertToPointerRoot, CurrentTime);
	}
#endif
}

uint64_t WindowManager::get_root_window() {
	return (uint64_t)root;
}

uint64_t WindowManager::get_active_window() {
	Window result = 0;
#ifdef LINUX
	mutex->lock();

	result = windows_stack.size() > 0 ? windows_stack.back() : 0;

	mutex->unlock();
#endif
	Godot::print(String("[WM] Active window returned: ") + Variant((uint64_t)result));
	fflush(stdout);
	fflush(stderr);
	return (uint64_t)result;
}

uint64_t WindowManager::get_focused_window() {
	Window result = 0;
	int revert_to_return;
#ifdef LINUX
	mutex->lock();

	XGetInputFocus(display, &result, &revert_to_return);

	mutex->unlock();
#endif
	return (uint64_t)result;
}

String WindowManager::get_window_title(uint64_t window_id) {
	String title = "";
#ifdef LINUX
	mutex->lock();

	Godot::print(String("[WM] Trying to get title of window ") + Variant(window_id));
	fflush(stdout);
	fflush(stderr);
	if (windows_names.has(window_id)) {
		title = windows_names[window_id];
	}
	while (title == "" && windows_parents.has(window_id)) {
		window_id = windows_parents[window_id];
		if (windows_names.has(window_id)) {
			title = windows_names[window_id];
		}
	}

	mutex->unlock();

	Godot::print("[WM] Window title received: " + title);
	fflush(stdout);
	fflush(stderr);
#endif
	return title;
} 

Array WindowManager::get_windows_stack() {
	Array stack;
#ifdef LINUX
	mutex->lock();

	for (auto it = windows_stack.begin(); it != windows_stack.end();) {
		stack.append((uint64_t)*it);
		++it;
	}

	mutex->unlock();
#endif
	return stack;
}

uint64_t WindowManager::get_window_id() {
	return (uint64_t)launcher;
}

void WindowManager::set_always_on_top(uint64_t window_id, bool always_on_top) {
#ifdef LINUX
	if (always_on_top) {
		top_window = (Window)window_id;
		printf("[WM] Set always on top window to %ld\n", top_window);
		XSetInputFocus(display, (Window)window_id, RevertToPointerRoot, CurrentTime);
		XRaiseWindow(display, (Window)window_id);
	} else {
		if (top_window == (Window)window_id) {
			XSetInputFocus(display, root, RevertToPointerRoot, CurrentTime);
			top_window = 0L;
		}
	}
#endif
}

bool WindowManager::is_always_on_top(uint64_t window_id) {
	bool always_on_top = false;
#ifdef LINUX
	always_on_top = (top_window == (Window)window_id);
#endif
	return always_on_top;
}

bool WindowManager::start() {
	if(!thread->is_active()) {
		thread->start(this, "_run", Variant());
		return true;
	}
	return false;
}

void WindowManager::_run(Array userdata) {
#ifdef LINUX
	if (!display) {
		fprintf(stderr, "[WM] X display not initialized!\n");
		return;
	}

	mutex->lock();

	XGrabServer(display);
	Window returned_root, returned_parent;
	Window* top_level_windows;
	unsigned int num_top_level_windows;
	if(!XQueryTree(
		display,
		root,
		&returned_root,
		&returned_parent,
		&top_level_windows,
		&num_top_level_windows) || root != returned_root) {
		
		fprintf(stderr, "[WM] Error during top level window scan\n");
	}
	XSetInputFocus(display, root, RevertToPointerRoot, CurrentTime);

	printf("[WM] Adding launcher %ld to the stack\n", launcher);
	windows_stack.push_back(launcher);
	input_focus = launcher;

	XClassHint ch;
	for (int i = 0; i < num_top_level_windows; ++i) {
		
		if (XGetClassHint(display, top_level_windows[i], &ch)) {
			//printf("Checking window with class %s during scan\n", ch.res_class);
			if (strstr(ch.res_class, "xcompmgr") || top_level_windows[i] == launcher) {
				// Compton is the compositor, skipping it
				//printf("Found the compton window %ld during scan\n", top_level_windows[i]);
				continue;
			}
		}
		windows_stack.push_back(top_level_windows[i]);
		printf("[WM] Added window %ld to the stack\n", top_level_windows[i]);
	}
	fflush(stdout);
	fflush(stderr);

	XFree(top_level_windows);
	XUngrabServer(display);

	// Trying to grab the entire keyboard
	XGrabKeyboard(display, root, False, GrabModeAsync, GrabModeAsync, CurrentTime);

	// Grabbing the alternative Start button
	/*XGrabKey(display, XKeysymToKeycode(display, XK_KP_Add), AnyModifier, root,
			True, GrabModeAsync, GrabModeAsync);*/
	// Also grabbing the default Start button
	/*XGrabKey(display, XKeysymToKeycode(display, XK_Return), 0, root,
			True, GrabModeAsync, GrabModeAsync);*/
	
	XEvent ev;

	mutex->unlock();
	for(;;) {

		XNextEvent(display, &ev);

		mutex->lock();
		//printf("[ Stack size at the beginning: %d ]\n", windows_stack.size());
		switch (ev.type) {
			case MapRequest:
					printf("[WM] MapRequest event received from %ld\n", ev.xmaprequest.window);
					
					fflush(stdout);
					stack_add_window(ev.xmaprequest.window);
					//grab_keys(ev.xmaprequest.window);

					break;
			case ConfigureRequest:
					printf("[WM] ConfigureRequest event received from %ld\n", ev.xconfigurerequest.window);
					fflush(stdout);
					{
						XWindowChanges wc;
						XConfigureRequestEvent *config_ev = &ev.xconfigurerequest;

						//print_class_and_name(ev.xconfigurerequest.window);

						wc.x = config_ev->x;
						wc.y = config_ev->y;
						Godot::print(String("[WM] Screen size: ") + OS::get_singleton()->get_screen_size(0));
						wc.width = OS::get_singleton()->get_screen_size(0).x;//config_ev->width;
						wc.height = OS::get_singleton()->get_screen_size(0).y;//config_ev->height;
						wc.border_width = 0;//config_ev->border_width;
						if (top_window > 0L) {
							wc.sibling = top_window;
							wc.stack_mode = Below;
						} else {
							wc.sibling = config_ev->above;
							wc.stack_mode = config_ev->detail;
						}
						// Setting window position and size doesn't work all the times yet. Need to investigate.
						XConfigureWindow(display, config_ev->window, /*config_ev->value_mask | */UINT_MAX, &wc);
						//printf("- Request by %ld permitted\n", ev.xconfigurerequest.window);
						//printf("- Shifted on the visibility stack with sibling %ld\n", wc.sibling);
					}
					// Check if window name is updated
					names_add_window(ev.xconfigurerequest.window);
					break;
			case PropertyNotify:
					if (ev.xproperty.atom == atom_name || ev.xproperty.atom == atom_net_name) {
						names_add_window(ev.xproperty.window);
					}
					break;
			case FocusIn:
					//printf("FocusIn event received from %ld\n", ev.xfocus.window);
					break;
			case UnmapNotify:
					//printf("UnmapNotify event received from %ld\n", ev.xunmap.window);
					fflush(stdout);
					{
						/*if (stack_has_window(ev.xunmap.window)) {
							ungrab_keys(ev.xunmap.window);
						}*/
						stack_remove_window(ev.xunmap.window);
						fflush(stdout);
					}
					break;
			case KeyPress:
					/*printf("KeyPress %s (keycode %d) event received from %ld\n", XKeysymToString(XkbKeycodeToKeysym(display, ev.xkey.keycode, 0, 0)), ev.xkey.keycode, ev.xkey.window);
					{
						godot::Array events = InputMap::get_singleton()->get_action_list("ui_menu");
						if (events.size() > 0) {
							Ref<InputEventKey> event = Ref<InputEventKey>(events[0]);
							Godot::print("Godot print of current MENU mapped event: " + String(event->as_text()));
							Godot::print(String("Godot print of current MENU mapped data: ") + Variant(event->get_scancode()));
							printf("Godot current MENU mapped key scancode is %d\n", event->get_scancode());
						}
					}*/
					//if (ev.xkey.keycode == XKeysymToKeycode(display, XK_Escape)) {
					//printf("- KeyPress passed the XK_Escape key check\n");
					if (launcher > 0) {
						XSendEvent(display, launcher, False, 0, &ev);
						//printf("- Sent to launcher %ld\n", launcher);
					}
					//}
					/*else */if (input_focus > 0 && input_focus != launcher) {
						ev.xkey.window = input_focus;
						XSendEvent(display, input_focus, False, 0, &ev);
						//printf("- Sent to %ld, event root is %ld, event subwindow is %ld\n", ev.xkey.window, ev.xkey.root, ev.xkey.subwindow);
					}
					break;
			case KeyRelease:
					//printf("KeyRelease %s event received from %ld\n", XKeysymToString(XkbKeycodeToKeysym(display, ev.xkey.keycode, 0, 0)), ev.xkey.window);
					if (launcher > 0) {
						XSendEvent(display, launcher, False, 0, &ev);
						//printf("- Sent to launcher %ld\n", launcher);
					}
					if (input_focus > 0 && input_focus != launcher/* && ev.xkey.keycode != XKeysymToKeycode(display, XK_Escape)*/) {
						ev.xkey.window = input_focus;
						XSendEvent(display, input_focus, False, 0, &ev);
						//printf("- Sent to %ld, event root is %ld, event subwindow is %ld\n", ev.xkey.window, ev.xkey.root, ev.xkey.subwindow);
					}
					break;
			case MapNotify:
					printf("[WM] MapNotify event received from %ld\n", ev.xmap.window);
					if (!stack_has_window(ev.xmap.window)) {
						//printf("- Was not in stack, trying to add and activate it.\n");
						stack_add_window(ev.xmap.window);
						//grab_keys(ev.xmap.window);
					} else {
						names_add_window(ev.xmap.window);
					}
					/*if (top_window > 0L) {
						printf("[WM] MapNotify raising always on top window %ld\n", top_window);
						raise_window(top_window);
					}*/
					break;
			case MappingNotify:
					printf("[WM] MappingNotify event received from %ld\n", ev.xmapping.window);
					break;
			case CreateNotify:
					//printf("CreateNotify event received from %ld\n", ev.xcreatewindow.window);
					break;
			case DestroyNotify:
					stack_remove_window(ev.xdestroywindow.window);
					//printf("DestroyNotify event received from %ld\n", ev.xdestroywindow.window);
					break;
			/*case VisibilityNotify:
					printf("VisibilityNotify event received from %ld\n", ev.xvisibility.window);
					if (ev.xvisibility.state != VisibilityUnobscured) {
						// Launcher is being fully obscured or partially obscured
						if (ev.xvisibility.window == launcher && launcher == top_window) {
							raise_window(launcher);
						}
					}
					break;*/
			case ReparentNotify:
					printf("[WM] ReparentNotify event received from %ld with new parent %ld\n", ev.xreparent.window, ev.xreparent.parent);
					if (ev.xreparent.parent != root) {
						//printf("- The new parent is not root, proceeding\n");
						if (stack_has_window(ev.xreparent.parent)) {
							stack_raise_window(ev.xreparent.parent);
							printf("[WM] - Raising parent window %ld on top of the stack\n", ev.xreparent.parent);
							raise_window(ev.xreparent.parent);
							//XRaiseWindow(display, ev.xreparent.parent);
							//XSetInputFocus(display, ev.xreparent.parent, RevertToPointerRoot, CurrentTime);
							XChangeProperty(display, root, atom_active_window,
									XA_WINDOW, 32, PropModeReplace, (unsigned char *) &(ev.xreparent.parent), 1);
						}
						//printf("- Now adding on top and activating the reparenting subwindow\n");
						stack_add_window(ev.xreparent.window);
						windows_parents[(uint64_t)ev.xreparent.window] = (uint64_t)ev.xreparent.parent;
					} else {
						// Update windows hierarchy
						windows_parents.erase((uint64_t)ev.xreparent.window);
					}
					break;
			default:
					//printf("Event %s ignored\n", type_names[ev.type]);
					break;
		}
		//printf("--- Stack size at the end: %d\n", windows_stack.size());
		fflush(stdout);
		fflush(stderr);

		mutex->unlock();
	}
#endif
}

void WindowManager::_register_methods() {
	register_method("activate_window", &WindowManager::activate_window);
	register_method("raise_window", &WindowManager::raise_window);
	register_method("lower_window", &WindowManager::lower_window);
	register_method("kill_window", &WindowManager::kill_window);
	register_method("give_focus", &WindowManager::give_focus);
	register_method("give_focus_to_active", &WindowManager::give_focus_to_active);

	register_method("get_root_window", &WindowManager::get_root_window);
	register_method("get_active_window", &WindowManager::get_active_window);
	register_method("get_focused_window", &WindowManager::get_focused_window);
	register_method("get_windows_stack", &WindowManager::get_windows_stack);
	register_method("get_window_title", &WindowManager::get_window_title);
	register_method("get_window_id", &WindowManager::get_window_id);
	register_method("set_always_on_top", &WindowManager::set_always_on_top);
	register_method("is_always_on_top", &WindowManager::is_always_on_top);

	register_method("start", &WindowManager::start);

	register_method("_ready", &WindowManager::_ready);
	register_method("_run", &WindowManager::_run);

	register_signal<WindowManager>("window_mapped", "window_id", GODOT_VARIANT_TYPE_INT);
	register_signal<WindowManager>("window_unmapped", "window_id", GODOT_VARIANT_TYPE_INT);
	register_signal<WindowManager>("active_window_changed", "window_id", GODOT_VARIANT_TYPE_INT);
	register_signal<WindowManager>("window_name_changed", "window_id", GODOT_VARIANT_TYPE_INT, "name", GODOT_VARIANT_TYPE_STRING);
}
