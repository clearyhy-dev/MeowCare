import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../core/constants/app_constants.dart';

class StorageRepository {
  StorageRepository() : _storage = FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadCatAvatar(String uid, String catId, File file) async {
    final ref = _storage.ref().child(AppConstants.storageAvatarsPath).child(uid).child('$catId.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadPostCover(String postId, File file) async {
    final lower = file.path.toLowerCase();
    final ext = lower.endsWith('.png')
        ? 'png'
        : lower.endsWith('.webp')
            ? 'webp'
            : 'jpg';
    final contentType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
            ? 'image/webp'
            : 'image/jpeg';
    final storageRef = _storage.ref().child(AppConstants.storageCoversPath).child('$postId.$ext');
    await storageRef.putFile(file, SettableMetadata(contentType: contentType));
    return storageRef.getDownloadURL();
  }
}
