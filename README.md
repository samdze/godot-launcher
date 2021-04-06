<p aling="center">
	<img src="https://i.imgur.com/3uJZK70.gif" />
</p>
# GameShell Godot Launcher
An alternative launcher for the GameShell portable console. Made with Godot and GDNative.

To explore the launcher code and tweak it as you wish, open the project.godot file with Godot 3.2.3.
Remember to reimport the launcher and to transfer the .import folder too to apply your changes.
Reimporting the project from the GameShell itself is not supported at the moment.

**NOTE**: the 512 MB or ram version of the GameShell is known to have issues with Godot using the lima driver.
Fbturbo should work ok but performances will be worse.

## Why
The stock launcher found in the GameShell lacks a few fundamental features when it comes to window management, multitasking and tweakability.
This launcher aims to fix all those issues and to add other nice features.

## Installation
SSH into the cpi home directory of the GameShell and run:
```
git clone https://github.com/samdze/godot-launcher.git
sed -i s/godot-launcher/launcher/g /home/cpi/.bashrc
```
Restart the GameShell and you should boot into the Godot launcher.
You can rollback to the stock launcher running the "Switch Launcher" app.

## Documentation
Press Shift + Start at any time when an app is open to show the launcher widgets.
In this state, you can then exit the app, go back to the app, see the time and the approximate remaining battery.

```
/home/cpi/
├── apps
│   ├── emulators
│   └── Menu
├── launchergodot 		<- Here we are
│   ├── .import			Imported files, this is generated and updated when you reload/import the launcher
│   ├── apps			Utilities and general purpose apps, you can tweak them or also add your own
│   ├── library			Native libreries used to create and handlle the window manager of the launcher
│   ├── system			System files and base infrastructure to build the launcher
│   ├── system			Theme-related files, used to define fonts, UI skins and more
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

## Requested features:
- wallpapers
- change the scrolling from left-and-right to up-and-down
- built-in option to change icons