import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogService {
  static final _supabase = Supabase.instance.client;

  static Future<void> saveBlog({
    String? id,
    required String title,
    required String content,
    Uint8List? webImage, 
    String? existingImageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    String? finalImageUrl = existingImageUrl;

    if (webImage != null) {
      final fileName = '${user!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage.from('blogs').uploadBinary(
            fileName,
            webImage,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
          
      finalImageUrl = _supabase.storage.from('blogs').getPublicUrl(fileName);
    }

    final data = {
      'user_id': user!.id,
      'title': title,
      'content': content,
      'image_url': finalImageUrl,
    };

    if (id == null) {
      await _supabase.from('blogs').insert(data);
    } else {
      await _supabase.from('blogs').update(data).eq('id', id);
    }
  }

  static Future<void> deleteRecord(String table, String id) async {
    await _supabase.from(table).delete().eq('id', id);
  }

  static Future<void> submitComment({
    String? id, 
    required String blogId,
    required String text,
    Uint8List? webImage,
  }) async {
    final user = _supabase.auth.currentUser;
    String? uploadedUrl;

    if (webImage != null) {
      final path = '${user!.id}/comment-images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('comments').uploadBinary(
            path,
            webImage,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      uploadedUrl = _supabase.storage.from('comments').getPublicUrl(path);
    }

    final Map<String, dynamic> data = {
      'content': text.trim(),
    };

    if (uploadedUrl != null) {
      data['image_url'] = uploadedUrl;
    }

    if (id == null) {
      data['blog_id'] = blogId;
      data['user_id'] = user!.id;
      await _supabase.from('comments').insert(data);
    } else {
      await _supabase.from('comments').update(data).eq('id', id);
    }
  }
}