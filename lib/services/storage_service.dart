import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

class StorageService {
  final FirebaseStorage _storage;
  StorageService(this._storage);

  // Upload audio file to Firebase Storage and return download URL
  Future<String> uploadAudio(String userId, String sessionId, int questionIndex, File file) async {
    var ref = _storage
        .ref()
        .child('users')
        .child(userId)
        .child('sessions')
        .child(sessionId)
        .child('answer_$questionIndex.aac');
    await ref.putFile(file);
    String downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }
}

// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return StorageService(storage);
});
