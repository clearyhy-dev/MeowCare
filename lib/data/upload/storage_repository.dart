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

  /// Ordered gallery image: `covers/{postId}_img_{index}.jpg`
  Future<String> uploadPostGalleryImage(String postId, int index, File file) async {
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
    final storageRef =
        _storage.ref().child(AppConstants.storageCoversPath).child('${postId}_img_$index.$ext');
    await storageRef.putFile(file, SettableMetadata(contentType: contentType));
    return storageRef.getDownloadURL();
  }

  /// `covers/{postId}_video.{mp4|mov}`
  Future<String> uploadPostVideo(String postId, File file) async {
    final lower = file.path.toLowerCase();
    final ext = lower.endsWith('.mov')
        ? 'mov'
        : lower.endsWith('.webm')
            ? 'webm'
            : 'mp4';
    final contentType = ext == 'mov'
        ? 'video/quicktime'
        : ext == 'webm'
            ? 'video/webm'
            : 'video/mp4';
    final storageRef = _storage.ref().child(AppConstants.storageCoversPath).child('${postId}_video.$ext');
    await storageRef.putFile(file, SettableMetadata(contentType: contentType));
    return storageRef.getDownloadURL();
  }

  /// JPEG poster for video.
  Future<String> uploadPostVideoThumbnail(String postId, File jpegFile) async {
    final storageRef =
        _storage.ref().child(AppConstants.storageCoversPath).child('${postId}_video_thumb.jpg');
    await storageRef.putFile(jpegFile, SettableMetadata(contentType: 'image/jpeg'));
    return storageRef.getDownloadURL();
  }
}
