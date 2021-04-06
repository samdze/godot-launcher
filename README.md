## GameShell Godot Launcher

To explore the launcher code and tweak it as you wish, open the project.godot file with Godot 3.2.3.
Remember to reload the launcher manually to apply your changes.

```
/home/cpi/
├── apps
│   ├── emulators
│   └── Menu
├── launchergodot 		<- Here we are
│   ├── .import			Imported files, this is generated and updated when you reload the launcher
│   ├── apps			Utilities and general purpose apps, you can tweak them or also add your own
│   ├── system			System files and base infrastructure to build the launcher
│   ├── widgets			Widgets of the system, you can tweak them or also add your own
│   └── project.godot	The launcher project file, open it to edit the launcher with the Godot editor
├── games
│   ├── FreeDM
│   ├── MAME
│ 	├── nxengine
│   └── ...
├── music
└── ...
```

### Packages needed:
- xdotool

### Requested features:
- wallpapers
- change the scrolling from left-and-right to up-and-down
- built-in option to change icons