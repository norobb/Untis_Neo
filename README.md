# UntisPlus (Neo Edition)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)

> **Der modernste Flutter Stundenplan-Client mit Blur Design und Neo Features.**

UntisPlus ist ein moderner, privatsphärefokussierter Flutter Client für WebUntis. Diese "Neo Edition" kombiniert das wunderschöne, transluzente Design von UntisPlus mit den exklusiven Features von UntisNeo-mobile: **KI Chatbot**, echter **Hausaufgaben-Sync** und ein **Notenrechner**. 

## ✨ Features

- 🎨 **Modernes Blur Design**: Wunderschöne, transluzente Unterrichtskarten und eine intuitive, flüssige Benutzeroberfläche in Flutter.
- 🤖 **Neo Smart-Assistant (Gemini)**: Integrierter KI-Chatbot, der deinen Stundenplan versteht. Lade Fotos von Arbeitsblättern hoch oder stelle Fragen zu deinem Unterricht!
- 📚 **Echter Hausaufgaben-Sync**: Zieht (im Gegensatz zu vielen anderen Third-Party-Clients) echte Hausaufgaben direkt über die JSON-RPC API aus WebUntis, inklusive Erledigt-Status.
- 📊 **Notenrechner**: Behalte deinen Notenschnitt im Auge mit einem dedizierten, komplett lokalen Notenrechner.
- 🔒 **Privatsphäre zuerst**: Deine Daten bleiben auf deinem Gerät. Keine Speicherung auf fremden Servern.

## 🚀 Installation

Dank GitHub Actions wird bei jedem neuen Release vollautomatisch eine `app-release.apk` kompiliert. 

1. Gehe auf die **Releases-Seite** dieses Repositories.
2. Lade die neueste `app-release.apk` herunter.
3. Öffne die Datei auf deinem Android-Smartphone und installiere sie (ggf. "Installation aus unbekannten Quellen" zulassen).

## 🛠️ Entwicklung

### Setup
1. Installiere das [Flutter SDK](https://flutter.dev/docs/get-started/install)
2. Repository klonen: `git clone https://github.com/yourusername/UntisPlus.git`
3. Abhängigkeiten laden: `flutter pub get`
4. App starten: `flutter run`

### Projektstruktur
- `lib/screens/`: Enthält alle Hauptansichten (Timetable, Homework, AI Chat, Notenrechner).
- `lib/core/`: Design Tokens, State Management und Helfer-Klassen.
- `lib/services/`: API-Integrationen (WebUntis, Gemini API, Background Services).

## 🤝 Contributing
Contributions sind willkommen! Erstelle einfach einen Fork, committe deine Änderungen in einem neuen Branch und öffne einen Pull Request.

---
*Disclaimer: UntisPlus (Neo Edition) ist ein inoffizieller Client und steht in keiner Verbindung zur Untis GmbH.*
