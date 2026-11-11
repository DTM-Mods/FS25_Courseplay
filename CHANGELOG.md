# Changelog

Versions are `<Courseplay version>-cc.<CourseCorrect build>`. The release workflow takes the notes for a
version from its `## <version>` section here.

## 8.1.0.3-cc.5

- Clear (forget the course) is there whenever Courseplay itself is not driving the course: also while
  AutoDrive or another helper drives the vehicle. It asks first, in the map's place.
- Minimized panel: Clear on the map (or next to Show map when the map is hidden) and New course next
  to Start, as the full panel has them.

## 8.1.0.3-cc.4

- Harvesters never take another harvester for a trailer. Two beet harvesters working side by side
  each saw the other one's bunker as something to unload into, opened the pipe over it and waited
  for the unloading to finish, so both stood still for good. The pipe controller skips harvesters
  in its trigger, and a Courseplay-driven harvester's discharge ignores a harvester under the pipe.
- Drive through what blocks the helper (new global setting, on by default): a helper that the
  proximity sensor has held up for 10 seconds, while the obstacle itself does not move, stops
  colliding with that kind of obstacle (vehicles, bales, trees, static objects, never the terrain)
  and drives through it until it is clear, then becomes solid again. Both vehicles of a deadlock
  do this, so they pass through each other. Server side only, like all helper logic.

## 8.1.0.3-cc.3

- Saved tab: the courses on the field the vehicle stands on are listed first, from any folder, with
  the ones made for the implement's work width before the others. Course rows show the course's
  field and work width (warning colour when the implement's differs), and Load / Go say so when the
  width does not match. The course files are read a few per frame, so the panel never stalls.

## 8.1.0.3-cc.2

- Finish time: next to the time left, the panel shows the game clock when the course will be done
  (progress bar, course details, fleet rows). Courseplay's remaining time is real time; the clock
  runs at the game's time scale.
- Fleet rows show the vehicle's main tank (grain tank, seeds, fertilizer, trailer) with what is in it
  and how full it is, and its fuel. Fuel under 15 % is shown in the warning colour.
- Fleet rows have a Course button: the other vehicle's course, progress and position on your own
  panel, with the others on its field and the course details. Enter vehicle and Stop from there,
  Backspace goes back to the list.

## 8.1.0.3-cc.1

First build with its own version number. Courseplay 8.1.0.3 plus upstream main as of 2026-11-01
(fuel-save motor restart, bunker silo race fix, pathfinder and course display fixes, DLC seeder
configuration, BR/PT/CZ/RU/UK translations), with the CourseCorrect panel:

- Course, Saved, Fleet and Settings tabs; minimized panel with map, Start/Stop, Make course and
  Positions on map
- Unloaders see the combine's course, progress and position; Go to combine (AutoDrive leg, unloader
  starts on arrival); Call truck from the combine
- Clickable map arrows with name tooltip
- Row overlap course generator setting; new courses start at the first waypoint
- Fix: the panel no longer holds the keyboard (Tab, E) while the mouse cursor is shown but not over it
- The version shows next to the panel title
