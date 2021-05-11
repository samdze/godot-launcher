<p align="center">
	<img src="https://i.imgur.com/3uJZK70.gif" />
</p>

# GameShell Godot Launcher
An alternative launcher for the GameShell portable console. Made with Godot and GDNative.<br>
The launcher could also run on other single-board computers, better support may be added in the future.<br>
**VERY EARLY ALPHA VERSION**

To explore the launcher code and tweak it as you wish, open the project.godot file with Godot 3.2.3.<br>
Remember to reimport the launcher and to transfer the .import folder too to apply your changes.<br>
Reimporting the project from the GameShell itself is not supported at the moment.

**NOTE**: the 512 MB or ram version of the GameShell is known to have issues with Godot using the lima driver.<br>
Fbturbo should work ok but performances will be worse.

## Why
The stock launcher found in the GameShell lacks a few fundamental features when it comes to window management, multitasking and tweakability.
This launcher aims to fix all those issues and to add other nice features.

## Installation
SSH into the cpi home directory of the GameShell and run:
```
git clone https://github.com/samdze/godot-launcher.git
sudo chmod +x godot-launcher/compton godot-launcher/godot
sed -i s/launcher/godot-launcher/g /home/cpi/.bashrc
```
Restart the GameShell and you should boot into the Godot launcher.<br>
You can rollback to the stock launcher running the "Switch Launcher" app.

## Documentation
Press Shift + Start at any time when an app is open to show the launcher widgets.<br>
In this state, you can then exit the app, go back to the app, see the time, the approximate remaining battery and the Wi-Fi connection status, tweak screen brightness and audio volume.

There's also a default Settings app that lets you change a few things about the launcher.
It works but it's settings are limited and aren't supposed to be edited right now.

This is a very early version of the launcher, some games and apps will not be shown and there's no way to configure bluetooth, graphics drivers, standby times etc.

```
/home/cpi/
├── apps
│   ├── emulators
│   └── Menu
│
├── godot-launcher 		<- Here we are
│   ├── .import			Imported files, this needs to be generated and updated when you modify the launcher
│   ├── apps			Utilities and app launchers, you can tweak them or also add your own
│   ├── library			Native libreries used to create and handle the window manager of the launcher
│   ├── system			System files and base infrastructure to build the launcher
│   ├── modules			Folder containing modular parts of the launcher
│   │   ├── default		The stock module, implements the default widgets, apps, themes, etc.
│   │   └── ...			You can add your own modules here!
│   ├── project.godot		The launcher project file, open it to edit the launcher with the Godot editor
│   ├── godot			The Godot Engine executable, used to run the launcher
│   ├── compton			The compositor, this should run together with the launcher
│   └── settings.conf		Launcher settings using a INI-style formatting
│
├── games
│   ├── FreeDM
│   ├── MAME
│   ├── nxengine
│   └── ...
├── music
└── ...
```