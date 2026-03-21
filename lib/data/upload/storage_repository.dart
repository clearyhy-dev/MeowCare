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
    final ref = _storage.ref().child(AppConstants.storageCoversPath).child('$postId.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
