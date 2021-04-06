session=${1:-gameshell}

case $session in
hdmi )
	;;
gameshell )
	feh --bg-center ~/launchergodot/wallpapers/loading.png
	exec ~/launchergodot/compton --vsync opengl --paint-on-overlay > /tmp/compton.log 2>&1 &
	exec godot --audio-driver Dummy ~/launchergodot/project.godot > /tmp/godot-launcher.log 2>&1
	;;
*)
	exec $1;;
esac
