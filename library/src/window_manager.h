#ifdef LINUX
#include <X11/Xlib.h>
#else
typedef void Display;
typedef uint64_t Window;
typedef void XErrorEvent;
typedef int Atom;
#endif
#include <Godot.hpp>
#include <Node.hpp>
#include <Thread.hpp>
#include <Mutex.hpp>
#include <Array.hpp>
#include <Dictionary.hpp>

#include <deque>

using namespace godot;

static const char *type_names[37] = {
	0,
	0,
   "KeyPress",
   "KeyRelease",
   "ButtonPress",
   "ButtonRelease",
   "MotionNotify",
   "EnterNotify",
	"LeaveNotify",
	"FocusIn",
	"FocusOut",
	"KeymapNotify",
	"Expose",
	"GraphicsExpose",
	"NoExpose",
	"VisibilityNotify",
	"CreateNotify",
	"DestroyNotify",
	"UnmapNotify",
	"MapNotify",
	"MapRequest",
	"ReparentNotify",
	"ConfigureNotify",
	"ConfigureRequest",
	"GravityNotify",
	"ResizeRequest",
	"CirculateNotify",
	"CirculateRequest",
	"PropertyNotify",
	"SelectionClear",
	"SelectionRequest",
	"SelectionNotify",
	"ColormapNotify",
	"ClientMessage",
	"MappingNotify",
	"GenericEvent",
	"LASTEvent"
};
static bool wm_detected = false;

class WindowManager : public Node {
	GODOT_CLASS(WindowManager, Node)

private:
	static int on_wm_detected(Display* display, XErrorEvent* e);
	static int on_x_error(Display* display, XErrorEvent* e);

	Display * display;
	Window root;
	Window launcher = 0L;
	Window input_focus = 0L;
	Window top_window = 0L;
	std::deque<Window> windows_stack;
	Dictionary windows_parents;
	Dictionary windows_names;

	Atom atom_active_window;
	Atom atom_supported;
	Atom atom_pid;
	Atom atom_net_name;
	Atom atom_name;

	Ref<Thread> thread;
	Ref<Mutex> mutex;
	
	void purge_window(Window w);
	void print_class_and_name(Window w);
	Window get_window_id_from_pid(unsigned long pid);
	Window search_window_for_pid(Window w, unsigned long pid);
public:
	WindowManager();
   void _init();
	void _ready();

	void stack_add_window(Window w);
	void stack_remove_window(Window w);
	void stack_raise_window(Window w);
	bool stack_has_window(Window w);

	void names_add_window(Window w);
	void names_remove_window(Window w);

	void activate_window(uint64_t window_id);
	void raise_window(uint64_t window_id);
	void lower_window(uint64_t window_id);
	void kill_window(uint64_t window_id);
	void give_focus(uint64_t window_id, bool force);
	void give_focus_to_active(bool force);

	uint64_t get_root_window();
	uint64_t get_active_window();
	uint64_t get_focused_window();
	String get_window_title(uint64_t window_id);
	Array get_windows_stack();
	void set_always_on_top(uint64_t window_id, bool always_on_top);
	bool is_always_on_top(uint64_t window_id);

	uint64_t get_window_id();

	bool start();
	void _run(Array userdata);

	static void _register_methods();
};
