# UntisPlus (Neo Edition)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)

> **Der modernste Flutter Stundenplan-Client für Android – mit Fokus auf Design, KI und Produktivität.**

UntisPlus ist ein privatsphärefokussierter WebUntis-Client, der das Beste aus zwei Welten vereint: Das ästhetische, transluzente Design von UntisPlus und die kraftvollen Features der Neo-Serie. 

## ✨ Features

- 🎨 **Modernes Glassmorphism-Design**: Wunderschöne, transluzente UI-Elemente mit flüssigen Animationen und dynamischen Material You Farbschemata.
- 🤖 **Neo KI-Assistent (Gemini/OpenAI)**: Ein intelligenter Begleiter, der deinen Stundenplan, deine Hausaufgaben und Prüfungen kennt. Nutze Bildanalyse für Arbeitsblätter oder frage nach deinem nächsten Schultag.
- 📚 **Erweiterter Hausaufgaben-Sync**: Nutzt die offizielle WebUntis REST-API für maximale Zuverlässigkeit. Inklusive Anzeige von Lehrern, Anmerkungen und einer "Verbleibende Tage" Visualisierung.
- 📅 **Prüfungsverwaltung**: Automatische Synchronisation deiner anstehenden Prüfungen direkt aus dem Klassenregister.
- 🚶 **NEU: Abwesenheits-Tracker**: Behalte den Überblick über deine Entschuldigungen und offenen Fehlzeiten direkt in der App.
- 📊 **Notenrechner**: Verwalte deine Noten komplett lokal und behalte deinen Schnitt im Auge.
- 🔒 **Privatsphäre & Speed**: Keine Tracker, kein Cloud-Zwang. Deine Daten werden direkt von WebUntis geladen und lokal verarbeitet.

## 🚀 Installation

Die App ist für **Android** optimiert. 

1. Gehe auf die **[Releases-Seite](https://github.com/yourusername/UntisPlus/releases)**.
2. Lade die neueste `app-release.apk` herunter.
3. Installiere die Datei auf deinem Smartphone (ggf. "Installation aus unbekannten Quellen" in den Einstellungen erlauben).

## 🛠️ Entwicklung

### Anforderungen
- Flutter SDK (^3.11.0)
- Android Studio / VS Code mit Flutter Extension
- Ein WebUntis-Account

### Setup
```bash
git clone https://github.com/yourusername/UntisPlus.git
cd UntisPlus
flutter pub get
flutter run
```

### Projektstruktur
- `lib/services/`: REST & JSON-RPC Integrationen (Homework, Exams, Absences).
- `lib/screens/`: Feature-basierte UI-Komponenten (Timetable, AI Assistant, Absences, etc.).
- `lib/core/`: Zentrales State Management und Design-System.

## 🤝 Mitwirken
Verbesserungsvorschläge und Bugfixes sind immer willkommen! Erstelle einfach einen Pull Request oder öffne ein Issue.

---
*Disclaimer: UntisPlus ist ein inoffizielles Community-Projekt und steht in keiner Verbindung zur Untis GmbH.*
