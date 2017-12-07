# Godot steam uploader

Tool used to export your game using godot engine 2.1 and to upload it on steam. Tested on debian buster 64

## Prerequisite

- [Godot Engine 2.1.4](https://godotengine.org/) installed and the godot binary has to be in the `PATH`

- [Steam account](http://store.steampowered.com/)

- [An application with 3 repositories created](https://partner.steamgames.com/doc/sdk/uploading)

- [Steam SDK](https://partner.steamgames.com/home), extract to the `sdk` directory.

- [GodotSteam](https://github.com/Gramps/GodotSteam) from Gramps

## Usage

```
godot-steam-uploader - build and upload your game on steam

Example:
	./godot-steam-uploader.sh -linux-depot-id=1001 -osx-depot-id=1002 -windows-depot-id=1003 -appid=1000 -game-path=/home/user/my-awesome-game -game-name=my-awesome-game -steam-username=username

Options:
	-game-name=GAME_NAME
		The name of the game (without extension)

	-appid=APP_ID
		The app id

	-game-path=GAME_PATH
		Absolute path to the game directory (engine.cfg file)

	-linux-depot-id=LINUX_DEPOT_ID
		The depot id for GNU/Linux platform

	-osx-depot-id=OSX_DEPOT_ID
		The depot id for OSX platform

	-windows-depot-id=WINDOWS_DEPOT_ID
		The depot id for Windows platform

	-steam-username=STEAM_USERNAME
		Your steam username
```

## License

See [license file](./LICENSE)
