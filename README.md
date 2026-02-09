# Spendly

**Traccia spese, abbonamenti e budget in modo semplice e veloce.**

Spendly è un'app mobile sviluppata in Flutter per gestire le proprie finanze personali direttamente dal telefono. Pensata per essere rapida e intuitiva, permette di registrare spese, monitorare abbonamenti ricorrenti e visualizzare statistiche dettagliate.

---

## Funzionalità

- **Registrazione spese** — Aggiungi spese con categoria, importo e data in pochi tap
- **Gestione abbonamenti** — Tieni traccia degli abbonamenti ricorrenti (mensili, annuali, ecc.)
- **Statistiche e grafici** — Visualizza l'andamento delle spese con grafici interattivi
- **Categorie personalizzabili** — Organizza le spese in categorie su misura
- **Tema chiaro/scuro** — Supporto completo per dark mode
- **Backup su Google Drive** — Salva e ripristina i dati tramite il tuo account Google
- **Widget home screen** — Controlla le spese direttamente dalla home del telefono (Android)
- **Notifiche** — Promemoria per abbonamenti e spese ricorrenti
- **Export CSV** — Esporta i dati delle spese in formato CSV per analisi esterne
- **Onboarding** — Guida interattiva al primo avvio

---

## Piattaforme supportate

| Piattaforma | Supporto |
|-------------|----------|
| Android     | ✅        |
| iOS         | ✅        |

---

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Database locale:** SQLite (sqflite)
- **Grafici:** fl_chart
- **Backup cloud:** Google Sign-In + Google Drive API
- **Notifiche:** flutter_local_notifications
- **UI:** Material Design 3, Google Fonts, Flutter Animate

---

## Struttura del progetto

```
lib/
├── main.dart                # Entry point dell'app
├── core/                    # Tema, utilità condivise
├── data/                    # Modelli dati e database
├── features/                # Schermate principali
│   ├── add_expense/         # Aggiunta spesa
│   ├── categories/          # Gestione categorie
│   ├── home/                # Schermata principale
│   ├── onboarding/          # Onboarding iniziale
│   ├── settings/            # Impostazioni
│   ├── statistics/          # Grafici e statistiche
│   └── subscriptions/       # Abbonamenti ricorrenti
├── providers/               # State management (Provider)
└── widgets/                 # Widget riutilizzabili
```

---

## Requisiti

- Flutter SDK >= 3.9.0
- Dart SDK >= 3.9.0
- Android Studio / Xcode (per build nativi)

## Installazione

```bash
# Clona il repository
git clone https://github.com/<tuo-username>/traccia_spese_rapide.git
cd traccia_spese_rapide

# Installa le dipendenze
flutter pub get

# Avvia su dispositivo/emulatore Android o iOS
flutter run
```

---

## Build

```bash
# APK Android
flutter build apk --release

# App Bundle Android (per Play Store)
flutter build appbundle --release

# iOS (richiede macOS con Xcode)
flutter build ios --release
```

---

## Licenza

Questo progetto è distribuito sotto licenza **MIT con obbligo di attribuzione**.

Sei libero di usare, modificare e distribuire questo software, anche in progetti commerciali, a condizione che venga mantenuta l'attribuzione all'autore originale nel codice sorgente e/o nella documentazione del progetto derivato.

Vedi il file [LICENSE](LICENSE) per i dettagli.
