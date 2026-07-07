# Launcher

### Windows
```
choco install -y python312
pip install --no-python-version-warning --disable-pip-version-check nuitka zstandard ordered-set -r requirements.txt
build_launcher.bat
```

### Linux (cross-compile to windows)

- It's not recommended to use the linux version of outlast for various reasons.

Provided as a containerfile for CI, though it'll compile fine if you just use the necessary commands from it on your host.

```
podman build -t outlast-launcher -f CI/Containerfile_launcher .
```

# UnrealScript

## Prerequisites
- A copy of Outlast
- [Outlast level editor](https://github.com/superboo07/Outlast-Level-Editor) (Don't forget to setup UDK like it tells you to)

### Windows

```
build_unrealscript.bat
```

### Linux

```
podman build -t outlast-unrealscript -f CI/Containerfile_unrealscript .
```

Output should be at `%UDK%\UDKGame\Script\Multiplayer.u`

See [the CI](./.github/workflows) for more details

# UnrealPackages

The .upks can be viewed & edited with the unreal editor (UDK.exe) provided with UDK setup alongside outlast level editor. They can optionally coooked for better performance. Whilst cooking them in theory should give better performance 99% of the time it ends up just being the same.

# Packaging for release

Here's file tree of a release zip for reference.

```text
OLGame
├── Config
│   ├── DefaultGame.ini
│   └── DefaultInput.ini
├── CookedPCConsole
    └── MultiplayerContent
        ├── ChrisPM.upk
        ├── EddiePM.upk
        ├── FaithPMContent.upk
        ├── FatherMartinPM.upk
        ├── Glitchy_Boi.upk
        ├── MilesPM.upk
        ├── Multiplayer.u
        ├── multiplayerassets.upk
        └── SurgeonPM.upk
OutlastLauncher.exe
```
