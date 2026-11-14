# ModHub upload: CourseCorrect

What to enter in the GIANTS ModHub upload form for this mod. Each text box below has a copy button on GitHub.

<img src="icon_512.png" alt="Mod icon" width="160">

**Mod Icon (512x512):** [`icon_512.png`](icon_512.png)

| Field | Value |
|-------|-------|
| Title English | CourseCorrect |
| Title German | CourseCorrect |
| Title French | CourseCorrect |
| Version | `8` `1` `0` `3` |
| Author | DTM Mods, Fennell (based on Courseplay by the Courseplay.devTeam) |
| Manufacturer | Lizard |
| Category 1 | Gameplay |
| Category 2 | Not Set |
| Category 3 | Not Set |

## Title English
```text
CourseCorrect
```

## Title German
```text
CourseCorrect
```

## Title French
```text
CourseCorrect
```

## Description English
```text
CourseCorrect is an edition of Courseplay, the long-running automation mod by the Courseplay dev team, based on Courseplay 8.1.0.3. Courseplay generates courses and lets helpers do fieldwork, harvest and unload, collect and wrap bales and work bunker silos. CourseCorrect adds a compact panel that replaces the stock HUD, plus a few helper fixes.

- Course tab: the course on a live map, progress, time left and finish time
- Saved tab: courses for the field you stand on and your implement's width come first
- Fleet tab: every Courseplay and AutoDrive vehicle of the farm with status, progress, load and fuel
- Call truck on a combine starts the nearest free truck as unloader; Go to combine sends a truck there with AutoDrive
- Harvesters never unload into another harvester
- Drive through what blocks the helper (on by default): a helper held up 10 seconds by something that does not move drives through it, never through the terrain
- Row overlap setting (0 to 20 %) for new courses

How to use: Courseplay menu > Settings > Global > HUD style: CourseCorrect (Classic brings the old HUD back).

Changelog 8.1.0.3 (CourseCorrect build 6):
- A helper whose unloading pipe has caught on a tree, building or vehicle beside it drives the pipe through it (never the terrain).
- Drive through what blocks the helper now covers every collision part of the vehicles, pipe arms included.
```

## Description German
```text
CourseCorrect ist eine Ausgabe von Courseplay, dem bewährten Automatisierungs-Mod des Courseplay-Teams, basierend auf Courseplay 8.1.0.3. Courseplay erstellt Kurse und lässt Helfer Feldarbeit erledigen, ernten und abtanken, Ballen sammeln und wickeln und Fahrsilos bearbeiten. CourseCorrect bringt ein kompaktes Panel anstelle des normalen HUDs und einige Verbesserungen für Helfer.

- Kurs-Reiter: der Kurs auf einer Live-Karte, Fortschritt, Restzeit und Uhrzeit des Arbeitsendes
- Gespeichert-Reiter: Kurse für das Feld, auf dem du stehst, und für die Arbeitsbreite des Geräts zuerst
- Flotten-Reiter: alle Courseplay- und AutoDrive-Fahrzeuge des Hofs mit Status, Fortschritt, Ladung und Kraftstoff
- "Abfahrer rufen" am Drescher startet das nächste freie Fahrzeug als Abfahrer; "Zum Drescher" schickt es mit AutoDrive hin
- Erntemaschinen tanken nie in eine andere Erntemaschine ab
- Durchfahren bei Blockade (standardmäßig an): ein Helfer, den 10 Sekunden lang etwas Unbewegtes aufhält, fährt hindurch, nie durch das Gelände
- Einstellung Überlappung Spuren (0 bis 20 %) für neue Kurse

Bedienung: Courseplay-Menü > Einstellungen > Global > HUD-Stil: CourseCorrect (Classic bringt das alte HUD zurück).

Changelog 8.1.0.3 (CourseCorrect Build 6):
- Ein Helfer, dessen Abtankrohr an einem Baum, Gebäude oder Fahrzeug daneben hängt, fährt mit dem Rohr hindurch (nie durch das Gelände).
- Durchfahren bei Blockade gilt jetzt für alle Kollisionsteile der Fahrzeuge, auch für Rohrarme.
```

## Description French
```text
CourseCorrect est une édition de Courseplay, le mod d'automatisation de l'équipe Courseplay, basée sur Courseplay 8.1.0.3. Courseplay crée des parcours et fait travailler les ouvriers : travaux des champs, récolte et déchargement, ramassage et enrubannage des balles, silos-couloirs. CourseCorrect ajoute un panneau compact à la place du HUD habituel et quelques corrections pour les ouvriers.

- Onglet Parcours : le parcours sur une carte en direct, progression, temps restant et heure de fin
- Onglet Enregistrés : les parcours du champ où vous êtes et de la largeur de votre outil en premier
- Onglet Flotte : véhicules Courseplay et AutoDrive de la ferme avec état, progression, charge, carburant
- « Appeler un camion » sur une moissonneuse lance le camion libre le plus proche, qui y va avec AutoDrive
- Les moissonneuses ne se vident jamais dans une autre moissonneuse
- Traverser ce qui bloque (actif par défaut) : un ouvrier bloqué 10 secondes par un obstacle immobile le traverse, jamais le terrain
- Réglage de chevauchement des passages (0 à 20 %) pour les nouveaux parcours

Utilisation : menu Courseplay > Réglages > Global > Style du HUD : CourseCorrect (Classic rétablit l'ancien HUD).

Changelog 8.1.0.3 (CourseCorrect build 6) :
- Un ouvrier dont la goulotte s'accroche à un arbre, un bâtiment ou un véhicule voisin la fait passer au travers (jamais le terrain).
- Traverser ce qui bloque concerne maintenant toutes les pièces de collision des véhicules, bras de goulotte compris.
```

## Before uploading

- This is a fork of Courseplay by the Courseplay dev team, which is already on ModHub. ModHub rejects copies of existing mods, so this needs the Courseplay team's permission; the zip name `FS25_Courseplay` and version 8.1.0.3 are the same as the official mod's.
- The version in modDesc.xml is `8.1.0.3-cc.6`; the suffix `-cc.6` was dropped because the form only takes four numbers (it is kept in the changelog line).
- 393 files would go into the zip; ModHub allows at most 128 (this repo's build has `max-files: 0`). The zip also carries test scripts (`scripts/test/`). All Lua files are under 0.5 MB.
- 76 of the mod's 744 French texts are still in English, many of them the CourseCorrect panel and the new settings (German is complete apart from 2).
- The mod's own modDesc.xml still has the original Courseplay description (with HTML links, English and German only, no CourseCorrect features), and its Czech, Chinese, Hungarian, Japanese and Korean titles still say Courseplay.
