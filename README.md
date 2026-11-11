<p align="center">
  <a href="https://github.com/DTM-Mods"><img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/dtm-header.jpg" alt="DTM Mods by PropaineX & Fennell" width="100%"></a>
</p>

# FS25_Courseplay (CourseCorrect panel fork)

A fork of [Courseplay for Farming Simulator 25](https://github.com/Courseplay/Courseplay_FS25)
with the **CourseCorrect panel**: a compact in-game HUD that replaces the stock
Courseplay HUD. Everything else is Courseplay as upstream ships it.

Select it in Courseplay > Settings > Global > HUD style = CourseCorrect.

Versions read `<Courseplay version>-cc.<CourseCorrect build>`, for example `8.1.0.3-cc.1`: the first part is the
upstream Courseplay release this fork is on, the number after `cc.` counts our builds on it. The panel shows it next
to its title, and the Fleet tab and the server need everyone on the same one.

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/features.jpg" alt="Features" width="100%">
</p>

## What the panel adds

- Course tab: the vehicle's course on a live map, progress with time left, the others working the same
  field as arrows, work width, field margin, row overlap and tool offset (shows the automatic plow offset).
- Saved tab: load and save courses. The courses on the field you stand on come first, from any folder,
  the ones made for your implement's work width before the others; each course shows its field and width.
- Fleet tab: every Courseplay and AutoDrive vehicle on the farm with status, progress, finish time,
  distance, main tank and fuel; click a row to enter the vehicle, or its Course button to see that
  vehicle's course and progress on your own panel (Enter vehicle and Stop from there).
- Finish time: the game clock when the course will be done, next to the time left.
- Settings tab: the vehicle's Courseplay settings.
- Minimized panel: small map, status, Start/Stop, "Make course" and "Positions on map" buttons.
- Unloaders: the combine's course, progress and position on the truck's panel. "Go to combine" sends a
  truck that is away from the field there with AutoDrive and starts the Courseplay unloader on arrival.
- Combines: "Call truck" lists the farm's free trucks nearest first and starts one as unloader, with an
  AutoDrive leg when it is far away.
- Map arrows are clickable (enter that vehicle) and show the vehicle's name on hover.
- Course generator: row overlap setting (centre rows, 0-20 %).
- Multiplayer: maps and statuses work on clients that never ran field detection.
- Harvesters never unload into another harvester (two beet harvesters side by side used to wait on
  each other for good).
- Drive through what blocks the helper (global setting, on by default): a helper held up for 10
  seconds by a vehicle or an object that does not move stops colliding with it and drives through.

The panel lives in `scripts/gui/hud/CpModernHud.lua` and `scripts/gui/hud/CpHudDraw.lua`; the row overlap
setting is in `scripts/courseGenerator/FieldworkContext.lua`; the drive-through logic is in
`scripts/ai/ProximityController.lua` and `scripts/ai/CollisionGhost.lua`.

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/installation.jpg" alt="Installation" width="100%">
</p>

Download `FS25_Courseplay.zip` from the [latest release](https://github.com/DTM-Mods/FS25_Courseplay/releases/latest) and put it in `Documents/My Games/FarmingSimulator2025/mods`, without unzipping or renaming it. In multiplayer, the server and every player need the same version.

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/license.jpg" alt="License" width="100%">
</p>

GPL-3.0, like upstream Courseplay. See `LICENSE.txt`. Courseplay is the work of the Courseplay dev team;
the CourseCorrect panel is the addition of this fork.

<details>
<summary><b>For developers</b>: files, building and tests</summary>

### Building

The Build workflow (`.github/workflows/build.yml`, shared DTM Mods steps) checks every push and builds
`FS25_Courseplay.zip` from the files git tracks, leaving out `.github`, Markdown and other development files.
A pushed tag `v<version in modDesc.xml>` (e.g. `v8.1.0.3-cc.2`) publishes a GitHub release with the zip.
To cut a build: bump `<version>` in `modDesc.xml`, add a `## <version>` section to `CHANGELOG.md`, commit, tag, push.
Locally the same script does it: `python ci/fs25_mod.py build --root . --out dist --name FS25_Courseplay`
(from the DTM-Mods/.github repository). Never rename the zip: savegames identify a mod by its file name.
Lua files must stay under 0.5 MB each for the GIANTS mod checks.

### Tests

Mods are Lua 5.1 and there is no standalone Lua here. The panel is tested offline with Python `lupa`
(Lua 5.1) plus engine stubs, rendering scenes to PNG and running behaviour tests. The upstream Courseplay
tests under `scripts/test` run the same way.

</details>

---

<p align="center">
  <a href="https://github.com/DTM-Mods"><img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/dtm-intro.gif" alt="DTM Mods by PropaineX & Fennell" width="420"></a><br>
  <sub>Part of <a href="https://github.com/DTM-Mods">DTM Mods</a> (Dead To Me) by PropaineX & Fennell</sub>
</p>
