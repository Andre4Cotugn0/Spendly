import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import '../database/database_helper.dart';

/// Client HTTP autenticato per Google Drive
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

/// Servizio per backup automatico su Google Drive
class GoogleDriveService {
  static final GoogleDriveService instance = GoogleDriveService._init();
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      drive.DriveApi.driveFileScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  
  static const String _backupFileName = 'traccia_spese_backup.json';
  static const String _backupFolderName = 'Spendly';

  GoogleDriveService._init();

  bool get isSignedIn => _currentUser != null;
  String? get userEmail => _currentUser?.email;
  String? get userName => _currentUser?.displayName;
  String? get userPhoto => _currentUser?.photoUrl;

  /// Verifica se l'utente è già loggato silenziosamente
  Future<bool> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initDriveApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Errore sign in silenzioso: $e');
      return false;
    }
  }

  /// Login con Google
  Future<bool> signIn() async {
    try {
      // Su iOS, controlla se la configurazione è stata fatta
      if (!kIsWeb && Platform.isIOS) {
        debugPrint('Tentativo di login Google su iOS - verifica configurazione Info.plist');
      }
      
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        await _initDriveApi();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Errore sign in: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      
      // Su iOS, fornisci un messaggio più chiaro
      if (!kIsWeb && Platform.isIOS) {
        if (e.toString().contains('DEVELOPER_ERROR') || 
            e.toString().contains('missing') ||
            e.toString().contains('invalid')) {
          throw Exception(
            'Google Sign-In non configurato correttamente per iOS. '
            'Verifica che il REVERSED_CLIENT_ID sia configurato in Info.plist. '
            'Consulta GOOGLE_SIGNIN_SETUP.md per le istruzioni.'
          );
        }
      }
      
      // Rilancia l'eccezione originale
      rethrow;
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _driveApi = null;
  }

  Future<void> _initDriveApi() async {
    if (_currentUser == null) return;
    
    final auth = await _currentUser!.authentication;
    final headers = {
      'Authorization': 'Bearer ${auth.accessToken}',
    };
    
    final client = GoogleAuthClient(headers);
    _driveApi = drive.DriveApi(client);
  }

  /// Trova o crea la cartella dell'app su Drive
  Future<String?> _getOrCreateBackupFolder() async {
    if (_driveApi == null) return null;

    try {
      // Cerca la cartella esistente
      final folderList = await _driveApi!.files.list(
        q: "name='$_backupFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
        spaces: 'drive',
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        return folderList.files!.first.id;
      }

      // Crea la cartella
      final folder = drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await _driveApi!.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      debugPrint('Errore creazione cartella: $e');
      return null;
    }
  }

  /// Esegue il backup dei dati su Google Drive
  Future<bool> backup() async {
    if (_driveApi == null) {
      final signedIn = await signInSilently();
      if (!signedIn) return false;
    }

    try {
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) return false;

      // Esporta i dati dal database
      final data = await DatabaseHelper.instance.exportAllData();
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);

      // Cerca se esiste già un file di backup
      final existingFiles = await _driveApi!.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
      );

      final media = drive.Media(
        Stream.value(bytes),
        bytes.length,
      );

      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        // Aggiorna il file esistente
        await _driveApi!.files.update(
          drive.File(),
          existingFiles.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        // Crea nuovo file
        final file = drive.File()
          ..name = _backupFileName
          ..parents = [folderId];

        await _driveApi!.files.create(
          file,
          uploadMedia: media,
        );
      }

      debugPrint('Backup completato con successo');
      return true;
    } catch (e) {
      debugPrint('Errore backup: $e');
      return false;
    }
  }

  /// Ripristina i dati da Google Drive
  Future<bool> restore() async {
    if (_driveApi == null) {
      final signedIn = await signInSilently();
      if (!signedIn) return false;
    }

    try {
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) return false;

      // Cerca il file di backup
      final files = await _driveApi!.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
      );

      if (files.files == null || files.files!.isEmpty) {
        debugPrint('Nessun backup trovato');
        return false;
      }

      // Scarica il file
      final fileId = files.files!.first.id!;
      final response = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
      }

      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Importa i dati nel database
      await DatabaseHelper.instance.importAllData(data);

      debugPrint('Ripristino completato con successo');
      return true;
    } catch (e) {
      debugPrint('Errore ripristino: $e');
      return false;
    }
  }

  /// Ottiene la data dell'ultimo backup
  Future<DateTime?> getLastBackupDate() async {
    if (_driveApi == null) {
      final signedIn = await signInSilently();
      if (!signedIn) return null;
    }

    try {
      final folderId = await _getOrCreateBackupFolder();
      if (folderId == null) return null;

      final files = await _driveApi!.files.list(
        q: "name='$_backupFileName' and '$folderId' in parents and trashed=false",
        spaces: 'drive',
        $fields: 'files(modifiedTime)',
      );

      if (files.files == null || files.files!.isEmpty) {
        return null;
      }

      return files.files!.first.modifiedTime;
    } catch (e) {
      debugPrint('Errore recupero data backup: $e');
      return null;
    }
  }
}
