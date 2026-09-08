WROUGHTWILD - WINDOWS PLAYTEST

Extract the entire ZIP to a writable local folder and open Wroughtwild.exe.
Keep the EXE, PCK, rules DLL and data folder together. No editor, checkout,
compiler or internet connection is required to play.

Choose a class and a world seed, or Continue a saved world / suspended trial.
H opens Controls & comfort; it includes current key bindings and Help.
F5 saves, F9 loads. Trial suspension is available at a cleared descent lift.
The window title and H display the source version; build-manifest.json records
that revision and checksums. Include the version and world seed in feedback.

Saves and preferences use the existing Windows location:
  %APPDATA%\Godot\app_userdata\Wroughtwild\
  wroughtwild_save.json (and .previous backup)
  audio-preferences.cfg (camera, sound, display and controls)
The portable package does not carry a save or import one automatically.
Close the other game before using the same save. Back up the entire save folder
before copying an existing checkpoint to another computer. A suspended trial
stays in its paired world file; do not split or merge its contents.

This unsigned prototype was tested on the development Windows machine.
Other computers, drivers and security prompts remain unverified. Forward+
rendering requires a compatible graphics device/driver. This is a local
playtest build, not a signed installer or store release.

Engine: Godot 4.5-stable. https://godotengine.org/license/
Godot-NOTICES.json includes the engine and its third-party license notices.
GDExtension bindings: godot-cpp, license included alongside this file.
