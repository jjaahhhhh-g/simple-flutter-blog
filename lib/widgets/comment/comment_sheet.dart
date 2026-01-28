import 'dart:io';
import 'package:blogs/widgets/comment/comment_input_bar.dart';
import 'package:blogs/widgets/comment/comment_item.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blogs/services/auth_services.dart';
import 'package:blogs/services/blog_services.dart';
import 'package:blogs/widgets/blogs_dialogs.dart';

class CommentSheet {
  static String _formatTimeAgo(String timestamp) {
    DateTime postDate = DateTime.parse(timestamp);
    Duration diff = DateTime.now().difference(postDate);
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  static void show(BuildContext context, String postId) {
    final controller = TextEditingController();
    File? selectedImage;
    String? editingCommentId;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {

          void cancelEdit() {
            setSheetState(() {
              editingCommentId = null;
              controller.clear();
            });
          }

          Future<void> handleDelete(String id) async {
            bool confirm = await BlogDialogs.showDeleteDialog(context, "Comment");
            if (!confirm) return;
            try {
              setSheetState(() => isSubmitting = true);
              await BlogService.deleteRecord('comments', id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted")));
              }
            } finally {
              setSheetState(() => isSubmitting = false);
            }
          }

          Future<void> handleSend() async {
            if (controller.text.trim().isEmpty && selectedImage == null) return;
            
            setSheetState(() => isSubmitting = true);
            try {
              if (editingCommentId != null) {
                await Supabase.instance.client.from('comments')
                    .update({'content': controller.text.trim()})
                    .eq('id', editingCommentId!);
                cancelEdit();
              } else {
                String? uploadedUrl;
                if (selectedImage != null) {
                  final userId = AuthService().currentUserId;
                  final path = '$userId/comment-images/${DateTime.now().millisecondsSinceEpoch}';
                  await Supabase.instance.client.storage.from('comments').upload(path, selectedImage!);
                  uploadedUrl = Supabase.instance.client.storage.from('comments').getPublicUrl(path);
                }
                await Supabase.instance.client.from('comments').insert({
                  'blog_id': postId,
                  'user_id': AuthService().currentUserId,
                  'content': controller.text.trim(),
                  'image_url': uploadedUrl,
                });
                controller.clear();
                setSheetState(() => selectedImage = null);
              }
            } finally {
              setSheetState(() => isSubmitting = false);
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              builder: (_, scrollController) => Column(
                children: [
                  if (isSubmitting) const LinearProgressIndicator(),
                  _buildHeader(editingCommentId != null),
                  Expanded(
                    child: _buildCommentList(postId, scrollController, editingCommentId, (comm) {
                      setSheetState(() {
                        editingCommentId = comm['id'].toString();
                        controller.text = comm['content'] ?? "";
                      });
                    }, handleDelete),
                  ),
                  CommentInputBar(
                    controller: controller,
                    selectedImage: selectedImage,
                    isSubmitting: isSubmitting,
                    isEditing: editingCommentId != null,
                    onImagePick: (file) => setSheetState(() => selectedImage = file),
                    onSend: handleSend,
                    onCancel: cancelEdit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static Widget _buildHeader(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Text(
        isEditing ? "Editing Comment..." : "Comments",
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
      ),
    );
  }

  static Widget _buildCommentList(String postId, ScrollController scroll, String? editingId, Function(Map<String, dynamic>) onEdit, Function(String) onDelete) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('comment_with_profile')
          .stream(primaryKey: ['id'])
          .eq('blog_id', postId)
          .order('created_at'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error loading comments"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final comments = snapshot.data!;
        if (comments.isEmpty) return const Center(child: Text("Be the first to comment!"));

        return ListView.builder(
          controller: scroll,
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comm = comments[index];
            final String commentId = comm['id'].toString();
            return CommentItem(
              comm: comm,
              isOwner: comm['user_id'] == AuthService().currentUserId,
              isEditing: editingId == commentId,
              onEdit: (selectedComment) {
                onEdit(selectedComment); 
              },
              onDelete: (id) {
                onDelete(id.toString());
              },
              formatTime: _formatTimeAgo,
            );
          },
        );
      },
    );
  }
}