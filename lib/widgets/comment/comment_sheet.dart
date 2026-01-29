import 'dart:typed_data';
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
    Uint8List? selectedWebImage; 
    String? editingCommentId;
    bool isSubmitting = false;
    Key streamKey = UniqueKey();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          
          void onTextChanged() {
            if (context.mounted) setSheetState(() {});
          }
          controller.removeListener(onTextChanged);
          controller.addListener(onTextChanged);

          void cancelEdit() {
            setSheetState(() {
              editingCommentId = null;
              controller.clear();
              selectedWebImage = null;
            });
            FocusScope.of(context).unfocus(); 
          }

          Future<void> handleDelete(String id) async {
            bool confirm = await BlogDialogs.showDeleteDialog(context, "Comment");
            if (!confirm) return;
            try {
              setSheetState(() => isSubmitting = true);
              await BlogService.deleteRecord('comments', id);
            } finally {
              if (context.mounted) setSheetState(() => isSubmitting = false);
            }
          }

          Future<void> handleSend() async {
          if (controller.text.trim().isEmpty && selectedWebImage == null) return;
          
          setSheetState(() => isSubmitting = true);
          try {
            await BlogService.submitComment(
              id: editingCommentId, 
              blogId: postId,
              text: controller.text,
              webImage: selectedWebImage, 
            );
            
            cancelEdit(); 
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
            }
          } finally {
            if (context.mounted) setSheetState(() => isSubmitting = false);
          }
        }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                if (isSubmitting) const LinearProgressIndicator(),
                _buildHeader(editingCommentId != null),
                Expanded(
                  child: _buildCommentList(
                    postId, 
                    ScrollController(), 
                    editingCommentId, 
                    streamKey, 
                    (comm) {
                      setSheetState(() {
                        editingCommentId = comm['id'].toString();
                        controller.text = comm['content'] ?? "";
                        selectedWebImage = null;
                      });
                    }, 
                    handleDelete
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: CommentInputBar(
                    controller: controller,
                    selectedImage: selectedWebImage,
                    isSubmitting: isSubmitting,
                    isEditing: editingCommentId != null,
                    onImagePick: (file) async {
                      if (file == null) {
                        setSheetState(() => selectedWebImage = null);
                        return;
                      }
                      final bytes = await file.readAsBytes();
                      setSheetState(() => selectedWebImage = bytes);
                    },
                    onSend: handleSend,
                    onCancel: cancelEdit,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildHeader(bool isEditing) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEditing ? "Editing Comment..." : "Comments",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
          ),
          if (isEditing)
            const Text(
              "(Image won't be replaced unless changed)",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  static Widget _buildCommentList(String postId, ScrollController scroll, String? editingId, Key key, Function(Map<String, dynamic>) onEdit, Function(String) onDelete) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: key, 
      stream: Supabase.instance.client
          .from('comment_with_profile')
          .stream(primaryKey: ['id'])
          .eq('blog_id', postId)
          .order('created_at'),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Error loading comments"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final comments = snapshot.data!;
        
        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: comments.isEmpty 
            ? ListView( 
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text("Be the first to comment!")),
                ],
              )
            : ListView.builder(
                controller: scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comm = comments[index];
                  return CommentItem(
                    comm: comm,
                    isOwner: comm['user_id'] == AuthService().currentUserId,
                    isEditing: editingId == comm['id'].toString(),
                    onEdit: onEdit,
                    onDelete: onDelete,
                    formatTime: _formatTimeAgo,
                  );
                },
              ),
        );
      },
    );
  }
}