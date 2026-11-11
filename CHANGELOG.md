# Changelog

Versions are `<Courseplay version>-cc.<CourseCorrect build>`. The release workflow takes the notes for a
version from its `## <version>` section here.

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
