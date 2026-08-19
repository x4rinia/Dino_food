# Dino_food 🦕🥦

**Dino_food** ist eine moderne, intuitive und gemeinsame Einkaufslisten-App für Haushalte, WGs, Paare und Familien. Sie kombiniert eine unkomplizierte Einkaufsliste mit praktischer Vorratsverwaltung und einer intelligenten Gerichte-Sammlung – alles in Echtzeit synchronisiert!

---

## ✨ Features & Funktionen

### 🛒 1. Gemeinsame Einkaufsliste (Echtzeit)
* **Live-Synchronisation:** Änderungen von Haushaltsmitgliedern erscheinen sofort auf allen Geräten (via Supabase Realtime).
* **Einfache Struktur:** Artikel bestehen aus **Name + optionaler Anzahl + optionaler Notiz** (z. B. *„Tomaten – 4 (Bitte Cherrytomaten)“* oder einfach *„Brot“*).
* **Keine störenden Einheiten:** Keine lästigen Dropdowns für Gramm, Liter oder Packungen – reine, unkomplizierte Zahlen.
* **Erledigte Artikel:** Einfaches Abhaken und mit einem Klick gesammeltes Aufräumen.

### 🍲 2. Gerichte & Smarte Zutaten-Übernahme
* **Einfache Gerichte:** Schnelles Erstellen und Bearbeiten von gespeicherten Lieblingsgerichten (z. B. *Spaghetti Bolognese*, *Kartoffelauflauf*, *Chili con Carne*).
* **1-Klick-Übernahme:** Alle Zutaten eines Gerichts landen direkt auf der Einkaufsliste.
* **Smarte Vorschau & Duplikat-Vermeidung:** Vor dem Hinzufügen prüft die App:
  * **Was ist bereits zuhause im Vorrat?** -> Wird automatisch übersprungen.
  * **Was steht bereits offen auf der Einkaufsliste?** -> Wird nicht doppelt angelegt.
  * **Was fehlt tatsächlich?** -> Nur diese Zutaten werden hinzugefügt.
* **❤️ Favoriten:** Bis zu 5 persönliche Lieblingsgerichte pro Benutzer, die in der Übersicht immer ganz oben stehen.

### 🏠 3. Haushalts-Vorrat (`Zuhause vorhanden`)
* **Minimalistisch & praktisch:** Keine komplizierten Grammzählungen oder Bestandsinventare – einfaches Markieren: *„Haben wir zuhause“* oder *„Haben wir nicht zuhause“*.
* **Haushaltsweit geteilt:** Alle Haushaltsmitglieder sehen denselben Vorratsstatus in Echtzeit.

### 🥕 4. Großer Lebensmittelkatalog
* **175+ integrierte Lebensmittel:** Sofortige Auswahl typischer Lebensmittel, sortiert in 21 übersichtliche Kategorien (*Gemüse, Obst, Fleisch, Wurst, Fisch, Milchprodukte, Käse, Brot & Backwaren, Nudeln & Reis, Gewürze, Getränke u.v.m.*).
* **Schnellsuche:** Blitzschnelle, fehlertolerante Suche beim Eintippen.
* **Eigene Lebensmittel:** Fehlende Produkte können jederzeit mit einem Fingertipp hinzugefügt werden.

### 👥 5. Haushalte & Profile
* **Haushalt erstellen & teilen:** Jeder Haushalt hat einen einfachen Einladungscode (z. B. `DINO-4F8K`).
* **Gemeinsam nutzen:** Familienmitglieder oder WG-Partner treten einfach per Code bei.
* **Haushalt umbenennen:** Der Haushaltsname kann jederzeit flexibel angepasst werden.

---

## 🛠️ Technologie-Stack

* **Frontend:** [Flutter](https://flutter.dev) (Dart) – Für Android, iOS, Web und Desktop
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Design & Theme:** Custom Dino-Green Soft UI mit Google Fonts & abgerundeten Cards
* **Backend:** [Supabase](https://supabase.com)
  * **Authentication:** Supabase Auth (E-Mail & Passwort)
  * **Database:** PostgreSQL mit Row Level Security (RLS)
  * **Realtime:** PostgreSQL CDC WebSocket Subscriptions

---

## 🚀 Installation & Start

### Voraussetzungen
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.x oder neuer)
* Ein [Supabase](https://supabase.com)-Projekt

### 1. Repository klonen
```bash
git clone https://github.com/x4rinia/Dino_food.git
cd Dino_food
```

### 2. Abhängigkeiten installieren
```bash
flutter pub get
```

### 3. Supabase Datenbank einrichten
Führe die SQL-Migrationsdateien im **Supabase SQL Editor** aus:
1. `supabase_schema.sql` (Grundtabellen, RLS & Trigger)
2. `supabase/migrations/seed_foods_and_default_dishes.sql` (Lebensmittel & Standardgerichte)

### 4. Supabase Credentials konfigurieren
Trage deine Supabase-URL und deinen Anon-Key in `lib/config/supabase_config.dart` oder über Umgebungsvariablen ein:
```dart
static const String supabaseUrl = 'https://dein-projekt.supabase.co';
static const String supabaseAnonKey = 'dein-anon-key';
```

### 5. App starten
```bash
# Im Web-Browser starten
flutter run -d chrome

# Auf einem Android-Gerät / Emulator starten
flutter run -d android
```

---

## 📱 Projektstruktur

```text
lib/
├── config/             # Theme, Farbpalette & Supabase-Konfiguration
├── models/             # Datenmodelle (ShoppingItem, Food, Dish, Household)
├── providers/          # State Management (Shopping, Stock, Food, Dish, Auth, Household)
├── screens/
│   ├── auth/           # Login & Registrierung
│   ├── dishes/         # Gerichte-Übersicht, Detail & Vorschau-Dialog
│   ├── foods/          # Lebensmittelkatalog & Vorratsverwaltung
│   ├── home/           # Bottom Navigation & App Shell
│   ├── household/      # Haushalt erstellen, beitreten & Einstellungen
│   └── shopping_list/  # Hauptansicht der Einkaufsliste & Schnelleingabe
├── services/           # Supabase Service-Layer & API-Calls
└── widgets/            # Wiederverwendbare UI-Komponenten (DinoCard, EmptyState)
```

---

## 🦖 Lizenz & Autor

Entwickelt von **[X4rinia](https://github.com/x4rinia)** 🦕
