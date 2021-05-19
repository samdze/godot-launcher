<p align="center">
	<img src="https://i.imgur.com/Qw2MiJb.gif" />
	<img src="https://i.imgur.com/BgUXz5O.gif" />
</p>

# Single-board Computer Godot Launcher
An alternative launcher for single-board computers. Made with Godot and GDNative.<br>
The launcher is primarily made to run on the GameShell portable console but can also run on other sbcs thanks to modules.<br>
**ALPHA VERSION**

To explore the launcher code and tweak it as you wish, open the project.godot file with Godot 3.2.3.<br>
Remember to reimport the launcher and to transfer the .import folder too to apply your changes.<br>
Reimporting the project from the GameShell itself is not supported at the moment.

**NOTE**: the 512 MB or ram version of the GameShell is known to have issues with Godot using the lima driver.<br>
Fbturbo should work ok but performances will be worse.

## Why
The stock launcher found in the GameShell lacks a few fundamental features when it comes to window management, multitasking and tweakability.
This launcher aims to fix all those issues and to add other nice features.

<p align="center">
	<img src="https://i.imgur.com/WiazXsL.png" />
	<img src="https://i.imgur.com/g2naCtR.png" />
</p>

## Installation
On the GameShell: ssh into the cpi home directory and run:
```
git clone https://github.com/samdze/godot-launcher.git
sed -i s/launcher/godot-launcher/g /home/cpi/.bashrc
```
Restart the GameShell and you should boot into the Godot launcher.<br>
You can rollback to the stock launcher selecting "Switch Launcher" inside the Settings app.

On other sbcs, start an X session executing the .xinitrc file.
```
git clone https://github.com/samdze/godot-launcher.git
startx godot-launcher/.xinitrc -- -nocursor
```
Better documentation will be available in the future.

## Documentation
On the GameShell, press Shift + START at any time when an app is open to show the launcher widgets.<br>
In this state, you can then exit the app, go back to the app, see the time, the approximate remaining battery and the Wi-Fi connection status, tweak screen brightness and audio volume.

The default Settings app lets you change a few things about the launcher, including input mappings.
This launcher is made to be modular and custom settings can be added by other modules.

This is an early version of the launcher, some games and apps may not be shown and there's no way to configure bluetooth, graphics drivers etc.

If your device isn't a GameShell, the launcher isn't quite ready to be fully usable, although it can run with a few tweaks.

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
│   ├── settings.conf		Launcher settings using a INI-style formatting
│   └── version.json		Version info, useful when checking for updates
│
├── games
│   ├── FreeDM
│   ├── MAME
│   ├── nxengine
│   └── ...
├── music
└── ...
```

## Compiling native libraries
A SCons 3.5+ installation is needed.

The steps below are assumed to be performed on a GameShell (armv7) device.

Build the Godot GDNative bindings found in library/godot-cpp inside the repository:

https://github.com/godotengine/godot-cpp/tree/3.2#compiling-the-c-bindings-library

Then compile the native window manager library; inside the library directory:
```
scons -j4
```