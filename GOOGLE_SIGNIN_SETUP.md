# Configurazione Google Sign-In per iOS

L'app richiede la configurazione di Google Sign-In per abilitare il backup su Google Drive su iOS.

## Passi per configurare Google Sign-In

### 1. Crea un progetto su Google Cloud Console

1. Vai su [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuovo progetto o seleziona uno esistente
3. Abilita le API necessarie:
   - Google Drive API
   - Google Sign-In API

### 2. Configura OAuth 2.0

1. Vai su **API & Services** > **Credentials**
2. Crea un **OAuth 2.0 Client ID** per iOS
3. Inserisci il Bundle ID dell'app: `com.andre4cotugn0.spendly`
4. Scarica il file di configurazione

### 3. Ottieni il REVERSED_CLIENT_ID

Dal file di configurazione scaricato (o dalla console), copia il valore del `REVERSED_CLIENT_ID`.

Esempio: `com.googleusercontent.apps.123456789012-abcdefghijklmnop`

### 4. Aggiorna Info.plist

Apri il file `ios/Runner/Info.plist` e sostituisci la riga:

```xml
<string>com.googleusercontent.apps.placeholder</string>
```

Con il tuo `REVERSED_CLIENT_ID`:

```xml
<string>com.googleusercontent.apps.123456789012-abcdefghijklmnop</string>
```

### 5. (Opzionale) Aggiungi GoogleService-Info.plist

Se usi Firebase, scarica il file `GoogleService-Info.plist` dalla console Firebase e aggiungilo nella cartella `ios/Runner/`.

### 6. Ricompila l'app

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

## Verifica

Dopo la configurazione:
1. Avvia l'app su iOS
2. Vai in Impostazioni
3. Prova ad accedere con Google
4. Se configurato correttamente, si aprirà il browser/app Google per l'autenticazione

## Problemi comuni

### L'app crasha al login
- Verifica che il REVERSED_CLIENT_ID sia corretto
- Controlla che il Bundle ID corrisponda
- Verifica che le API siano abilitate su Google Cloud Console

### Il login viene annullato
- Verifica che l'app Google sia installata o che il browser sia disponibile
- Controlla i permessi dell'app

### Errore "sign_in_failed"
- Il progetto Google Cloud potrebbe non essere configurato correttamente
- Verifica che l'OAuth client sia di tipo iOS
- Controlla che il Bundle ID sia esatto

## Contatto

Per assistenza sulla configurazione, contatta lo sviluppatore.
