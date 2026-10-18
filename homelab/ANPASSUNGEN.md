# HomeLabBooks: Eingriffe in die Audiobookshelf-App

Eigene Version der offiziellen Audiobookshelf-App (`advplyr/audiobookshelf-app`, GPL-3), Zweig `homelabbooks`
ab Tag `v0.14.2-beta`. Eigene Dateien liegen unter `homelab/`. Diese Liste nennt jede Änderung an fremden
Dateien, damit Updates von `upstream` leicht übernommen werden können (`git fetch upstream --tags`,
neuen Tag in `homelabbooks` mergen, Konflikte nur in den Dateien unten).

| Datei | Änderung |
|---|---|
| `capacitor.config.json` | `appId` `ch.gerber.homelabbooks`, `appName` `HomeLabBooks` |
| `ios/App/App/Info.plist` | `CFBundleDisplayName` = HomeLabBooks, `ITSAppUsesNonExemptEncryption` = false (keine Verschlüsselungsfrage pro Build), `UIApplicationSceneManifest` mit `SceneDelegate` und Storyboard «Main» statt `UIMainStoryboardFile` |
| `ios/App/App/AppDelegate.swift` | `window` ohne eigenes Fenster; neue Klasse `SceneDelegate` am Dateiende (reicht Links an Capacitor weiter). Nötig, weil iOS 27 Apps ohne Scene-Lebenszyklus beim Start beendet (Absturz von Build 1) |
| `ios/App/App.xcodeproj/project.pbxproj` | Bundle-ID `ch.gerber.homelabbooks` (Debug und Release), Team `C4LESUKP6H`, Version 1.0, eigene Build-Nummer, Mindest-iOS 15 (Xcode 27 kann kein iOS 14 mehr) |
| `ios/App/Podfile` (+ `Podfile.lock`) | `platform :ios, '15.0'` und im `post_install` alle Pods auf iOS 15 |
| `ios/App/App/Assets.xcassets/Icons.appiconset/*.png` | App-Symbol «HLB» (aus `homelab/icon_zeichnen.swift`) |
| `ios/App/App/Assets.xcassets/Splash.imageset/*.png` | Startbild dunkel mit Symbol (aus `homelab/startbild_zeichnen.swift`) |
| `static/Logo.png` | Logo der Anmeldeseite (Symbol mit runden Ecken) |
| `components/home/BookshelfNavBar.vue` | Eintrag «Entdecken» (Material-Symbol `explore`) nach «Home», nur bei Buch-Bibliotheken (markiert mit «HomeLabBooks») |
| `pages/bookshelf.vue` | Zähler-Leiste auf «Entdecken» ausgeblendet (`hideToolbar`, markiert mit «HomeLabBooks») |
| `components/connection/ServerConnectForm.vue` | Server-Adresse vorbelegt aus `homelab/einstellungen.js` (3 Zeilen, markiert mit «HomeLabBooks») |

## Bauen

- TestFlight: `homelab/testflight.sh` (Web-Teil bauen, `cap sync`, `pod install`, Build-Nummer +1, Archiv, Upload). Nur Archiv: `homelab/testflight.sh --nur-archiv`.
- Braucht `homelab/asc.env` (App-Store-Connect-API-Schlüssel, nicht in Git; derselbe wie bei HomeLabMusic) und `LANG=en_US.UTF-8` für CocoaPods (setzt das Skript).
- Symbol neu zeichnen: `xcrun swift homelab/icon_zeichnen.swift homelab/icon-1024.png`, dann die Grössen mit `sips -z <px> <px>` in `Icons.appiconset` (Dateiname `icon-<px>.png`).

## Eigene Teile (keine Konflikte bei Updates)

- `pages/bookshelf/entdecken.vue`: Tab «Entdecken» (Suchfeld, Reihen als Kartenbänder)
- `components/homelab/BuchKarte.vue`, `BuchDetails.vue`: Karte und Detailfenster mit «Hörbuch wünschen» und «E-Book wünschen»
- `homelab/buecher-api.js`: Aufrufe an `http://<Server>:30370/buecher/…` (Musikwunsch-Dienst, Modul `buchwunsch.py` im Repo homelab-migration) über `$nativeHttp`, Kopfzeile `X-ABS-Token`
