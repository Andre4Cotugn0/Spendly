# 🎨 Moneyra 2.0 – Sprint Redesign Grafico

> Redesign totale dell'interfaccia. Nuovi font, nuovi colori, nuovi layout.
> Tutte le funzionalità esistenti devono essere mantenute intatte.

---

## 📊 Stato Sprint – aggiornato 11 marzo 2026

| FASE | Stato |
|---|---|
| FASE 0 – Design System | ✅ Completata |
| FASE 1 – Shell & Nav | ✅ Completata |
| FASE 2 – Home Screen | ✅ Completata |
| FASE 3 – Add Expense | ✅ Completata |
| FASE 4 – Statistics | ✅ Completata |
| FASE 5 – Subscriptions | ✅ Completata |
| FASE 6 – Debts | ✅ Completata |
| FASE 7 – Settings | ✅ Completata |
| FASE 8 – Onboarding | ✅ Completata |
| FASE 9 – Categories | ✅ Completata |
| FASE 10 – Shared Widgets | ✅ Completata |
| FASE 11 – QA & Polish | ✅ Completata |

---

## 🎨 Nuovo Design System

### Palette colori (dal logo)
| Token | Light Mode | Dark Mode |
|---|---|---|
| `background` | `#F8FAFC` | `#0F172A` |
| `surface` | `#FFFFFF` | `#1E293B` |
| `surfaceVariant` | `#EFF4FF` | `#162040` |
| `surfaceLight` | `#E2E8F0` | `#334155` |
| `primary` | `#1F6BFF` | `#4A8CFF` |
| `primaryLight` | `#4A8CFF` | `#60A5FA` |
| `primaryContainer` | `#DBEAFE` | `#1E3A6E` |
| `textPrimary` | `#0F172A` | `#F8FAFC` |
| `textSecondary` | `#334155` | `#E2E8F0` |
| `textTertiary` | `#64748B` | `#94A3B8` |
| `border` | `#E2E8F0` | `#334155` |
| `success` | `#10B981` | `#34D399` |
| `warning` | `#F59E0B` | `#FBBF24` |
| `error` | `#EF4444` | `#F87171` |

**Gradiente primario**: `#1F6BFF → #4A8CFF` (135°)

### Tipografia: `Plus Jakarta Sans` (Google Fonts)
| Token | Size | Weight |
|---|---|---|
| `displayLarge` | 34px | 700 |
| `displayMedium` | 28px | 700 |
| `displaySmall` | 24px | 600 |
| `headlineMedium` | 20px | 600 |
| `headlineSmall` | 18px | 600 |
| `titleLarge` | 16px | 600 |
| `titleMedium` | 15px | 500 |
| `bodyLarge` | 16px | 400 |
| `bodyMedium` | 14px | 400 |
| `bodySmall` | 12px | 400 |
| `labelLarge` | 14px | 500 |

### Spacing tokens
`XS:4 / S:8 / M:16 / L:24 / XL:32 / XXL:48`

### Radius tokens
`XS:6 / S:12 / M:16 / L:24 / XL:32 / Full:999`

---

## ✅ FASE 0 – Design System Foundation `COMPLETATA`

- [x] Aggiornare `pubspec.yaml`: sostituire font Inter con Plus Jakarta Sans
- [x] Riscrivere `lib/core/theme/app_theme.dart`:
  - [x] Aggiornare `AppSeeds` con i nuovi colori primari (`#1F6BFF`, `#4A8CFF`)
  - [x] Ridefinire `AppColors` light mode con la nuova palette
  - [x] Ridefinire `AppColors` dark mode con la nuova palette
  - [x] Aggiornare `Dimens` con i nuovi spacing e radius tokens
  - [x] Sostituire `Inter` con `PlusJakartaSans` in tutta la typography
  - [x] Aggiornare `MoneyraColors` extension con i nuovi token (`surfaceVariant`, `border`, `primaryContainer`, ecc.)
  - [x] Ridefinire i `ThemeData` light e dark (inputDecoration, cardTheme, appBarTheme, bottomNavTheme)
  - [x] Aggiungere costante `AppGradients` con il gradiente primario `#1F6BFF → #4A8CFF`

---

## ✅ FASE 1 – Shell & Navigazione

- [x] Ridisegnare `HomeScreen` (shell con `IndexedStack`):
  - [x] Nuovo bottom navigation bar: sfondo `surface` con bordo top sottile `border`
  - [x] Icone con stato attivo in `primary`, inattivo in `textTertiary`
  - [x] FAB centrale: gradiente blu `#1F6BFF → #4A8CFF`, ombra `primary` 40% opacity, bordo bianco 2px
  - [x] Rimuovere doppio layer di ombra, sostituire con `elevation` + bordo sottile
  - [x] Mantenere tutte le animazioni icone nav (rotazione settings, bounce statistics, ecc.)

---

## ✅ FASE 2 – Home Screen

- [x] Ridisegnare `HomeContent`:
  - [x] Header: saluto dinamico ("Buongiorno") + mese corrente in un'unica riga
  - [x] Month selector: frecce `primary`, mese in `titleLarge`, sfondo trasparente
  - [x] **Balance card**: gradiente blu full-width, radius `XL:32`, importo in `displayLarge` bianco
    - [x] Sottotitolo budget: "€X di €Y disponibili"
    - [x] Progress bar sottile: `primaryContainer` come track, bianco come fill
    - [x] Etichetta mese/anno in `bodySmall` con opacity 0.7
  - [x] Search bar: input con sfondo `surfaceLight`, radius `Full:999`, icona lente `primary`
  - [x] Lista spese: card con sfondo `surface`, radius `M:16`, bordo `border` sottile
    - [x] Importo allineato a destra in `error`, `titleLarge`
    - [x] Icona categoria: background `primaryContainer`, icona tinta `primary`
    - [x] Data: `bodySmall` `textTertiary`, nome: `titleMedium` `textPrimary`
    - [x] Swipe-to-delete con feedback rosso mantenuto
  - [x] Empty state: testo `bodyMedium` `textSecondary`

---

## ✅ FASE 3 – Add Expense (Form)

- [x] Ridisegnare `AddExpenseScreen`:
  - [x] Header: titolo "Nuova Spesa" centrato, tasto X close a sinistra
  - [x] **Amount field**: importo grande centrato (56px, bold), `€` prefix in `textTertiary`
    - [x] Contenitore: sfondo `surfaceVariant`, radius `L:24`
    - [x] Label `labelMedium` `textTertiary` sopra il campo (rimuovere badge "IMPORTO")
  - [x] Date quick-buttons: pill `primaryContainer` + testo `primary` per selected; `surfaceLight` per unselected
  - [x] Category grid (4 colonne): card `surfaceLight` radius `M:16`, bordo `primary` 2px su selected
  - [x] Description field: sfondo `surfaceLight`, radius `M:16`
  - [x] Save button: gradiente blu full-width, radius `Full:999`, disabled in `surfaceLight`
  - [x] Mantenere tutte le animazioni esistenti

---

## ✅ FASE 4 – Statistics Screen

- [x] Ridisegnare `StatisticsScreen`:
  - [x] **Stats row** (3 quick-stats): card `surface` radius `L:24`, icona in cerchio `primaryContainer`
  - [x] **Donut chart** (buco centrale 45%): mostra importo totale al centro quando nessuna slice è selezionata
    - [x] Colori slice: shades del blu (`#1F6BFF`, `#4A8CFF`, `#60A5FA`, `#93C5FD`, ecc.)
    - [x] Legend: chip colorati con nome + importo
  - [x] **Comparison card**: sfondo `surfaceVariant`, variazione con `success`/`error`
  - [x] **Insights section**: separatori `divider`, icone `primary`
  - [x] **Category ranking**: badge numerati `primaryContainer`, top 3 in shades di blu
  - [x] **Line chart daily**: linea `primary`, fill gradient `primary → transparent`, dots `primary`
  - [x] **Top 5 expenses**: lista con `border` sottile, rank number in `primary`

---

## ✅ FASE 5 – Subscriptions Screen

- [x] Ridisegnare `SubscriptionsScreen`:
  - [x] Summary card mensile: gradiente blu, importo grande, radius `XL:32`
  - [x] Summary card annuale: sfondo `surfaceVariant`, radius `XL:32`
  - [x] Badge count sezione "Attive": `primaryContainer`
  - [x] Subscription item card: sfondo `surface`, radius `L:24`, bordo `border`
    - [x] Frequency badge: pill `primaryContainer` testo `primary`
    - [x] Prossima data: `bodySmall` `textTertiary`
  - [x] Bottom sheet opzioni: handle bar `border`, radius top `XL:32`

---

## ✅ FASE 6 – Debts Screen

- [x] Ridisegnare `DebtsScreen`:
  - [x] **"Devo"** summary card: sfondo `error` 15% opacity + bordo `error`, testo `error`
  - [x] **"Mi devono"** summary card: sfondo `success` 15% opacity + bordo `success`
  - [x] Debt item card: sfondo `surface`, radius `L:24`, progress bar `primary`
  - [x] Settled items: opacity 0.45 mantenuta
  - [x] Bottom sheet opzioni: stesso stile Subscriptions

---

## ✅ FASE 7 – Settings Screen

- [x] Ridisegnare `SettingsScreen`:
  - [x] Sezioni in card `surface` radius `L:24`, nessun divider pesante tra items della stessa card
  - [x] Tema selector: checkmark `primary`, chip selezionabili
  - [x] Budget section: progress bar `primary`
  - [x] Toggle switches: colore attivo `primary`
  - [x] Credits/info: link `primary`

---

## ✅ FASE 8 – Onboarding Screen

- [x] Ridisegnare `OnboardingScreen`:
  - [x] Slide icon container: cerchio gradiente blu `#1F6BFF → #4A8CFF`, 120×120, ombra `primary` 30%
  - [x] Titolo: `displaySmall` `textPrimary` centrato
  - [x] Sottotitolo: `bodyLarge` `textSecondary` centrato
  - [x] Dot indicator attivo: `primary` 24px, inattivi: `border` 8px
  - [x] Pulsante finale: gradiente blu full-width, radius `Full:999`, testo bianco

---

## ✅ FASE 9 – Categories Screen

- [x] Ridisegnare `CategoriesScreen`:
  - [x] Category item: sfondo `surface`, icona in cerchio `primaryContainer`, radius `M:16`
  - [x] Custom color picker: 12 colori in griglia, bordo `primary` 2px su selezionato
  - [x] Delete confirmation dialog: tasto confirm in `error`
  - [x] Add button FAB: gradiente blu coerente con FAB principale

---

## ✅ FASE 10 – Componenti Condivisi

- [x] Aggiornare `lib/widgets/category_icon.dart`:
  - [x] Container con sfondo `primaryContainer` (blue tint)
  - [x] ColorFilter SVG: tinta `primary` di default, colore custom mantenuto per categorie personalizzate
- [x] Aggiornare `lib/widgets/theme_transition_overlay.dart`:
  - [x] Colore overlay in `primary` con opacity ridotta
- [x] Standardizzare bottom sheets: handle bar, radius top `XL:32`, padding interni consistenti
- [x] Standardizzare dialogs: radius `L:24`, button stile flat `primary`
- [x] Standardizzare empty states: icona in `primaryContainer`, testo `textSecondary`

---

## ✅ FASE 11 – QA & Polish

- [x] Verificare contrasto testo/sfondo WCAG AA in light mode (ratio ≥ 4.5:1)
- [x] Verificare contrasto testo/sfondo WCAG AA in dark mode (ratio ≥ 4.5:1)
- [x] Test funzionalità complete post-redesign:
  - [x] Aggiunta, modifica e cancellazione spesa
  - [x] Abbonamenti: crea, modifica, pausa, cancella
  - [x] Debiti: crea, modifica, pagamento parziale, chiudi, riapri
  - [x] Statistiche: donut chart interattivo, line chart, insights
  - [x] Categorie: aggiungi custom, elimina
  - [x] Settings: cambio tema, budget, reminder, CSV export
  - [x] Onboarding: navigazione slide, skip, completa
- [x] Verificare animazioni `flutter_animate` non rotte
- [x] Verificare rendering SVG icone con nuova tinta blu
- [x] Verificare grafici `fl_chart` con nuovi colori
- [x] Test dark mode su tutti gli schermi
- [x] Test light mode su tutti gli schermi
- [x] Verificare `Plus Jakarta Sans` caricato correttamente

---

## 📦 File Coinvolti

| File | Tipo di modifica |
|---|---|
| `pubspec.yaml` | Font family → Plus Jakarta Sans |
| `lib/core/theme/app_theme.dart` | Riscrittura completa |
| `lib/features/home/home_screen.dart` | Shell + bottom nav + FAB |
| `lib/features/home/home_content.dart` | Balance card, lista spese |
| `lib/features/add_expense/*.dart` | Amount field, category grid, save button |
| `lib/features/statistics/*.dart` | Donut chart, line chart, stats cards |
| `lib/features/subscriptions/*.dart` | Summary cards, items, bottom sheet |
| `lib/features/debts/*.dart` | Summary cards, progress bar |
| `lib/features/settings/*.dart` | Sezioni card, toggles, selectors |
| `lib/features/onboarding/*.dart` | Slides, dots, pulsante |
| `lib/features/categories/*.dart` | Items, color picker, dialogs |
| `lib/widgets/category_icon.dart` | Container tinta primary blu |
| `lib/widgets/theme_transition_overlay.dart` | Colore overlay |

---

*Sprint generato l'11 marzo 2026 – Moneyra 2.0 Redesign*