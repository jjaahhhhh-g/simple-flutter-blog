import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Uint8List? selectedImage; 
  final bool isSubmitting;
  final bool isEditing;
  final Function(XFile?) onImagePick; 
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const CommentInputBar({
    super.key,
    required this.controller,
    required this.selectedImage,
    required this.isSubmitting,
    required this.isEditing,
    required this.onImagePick,
    required this.onSend,
    required this.onCancel,
  });


  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, 
    );

    if (image != null) {
      onImagePick(image);
    }
  }

  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                selectedImage!,
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: -5,
              right: -5,
              child: GestureDetector(
                onTap: () => onImagePick(null), 
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(50, 0, 0, 0),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedImage != null) _buildImagePreview(),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isEditing ? Icons.add_photo_alternate : Icons.image_outlined,
                    color: isSubmitting ? Colors.grey : (isEditing ? Colors.orange : Colors.blue),
                  ),
                  onPressed: isSubmitting ? null : _pickImage,
                ),
                
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: isSubmitting ? null : onCancel,
                  ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      autofocus: true,
                      controller: controller,
                      enabled: !isSubmitting,
                      maxLines: null, 
                      decoration: InputDecoration(
                        hintText: isEditing ? "Edit comment..." : "Add a comment...",
                        border: InputBorder.none,
                        hintStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                isSubmitting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          isEditing ? Icons.check_circle : Icons.send,
                          color: (controller.text.trim().isEmpty && selectedImage == null)
                              ? Colors.grey
                              : Colors.blue,
                        ),
                        onPressed: (controller.text.trim().isEmpty && selectedImage == null)
                            ? null
                            : onSend,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}