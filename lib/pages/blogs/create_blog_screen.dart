import 'dart:typed_data';
import 'package:blogs/services/blog_services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';

class CreateBlogScreen extends StatefulWidget {
  final Map<String, dynamic>? postData;
  const CreateBlogScreen({super.key, this.postData});

  @override
  State<CreateBlogScreen> createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _webImage; 
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.postData != null) {
      _titleController.text = widget.postData!['title'];
      _contentController.text = widget.postData!['content'];
      _existingImageUrl = widget.postData!['image_url'];
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _webImage = bytes;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill in all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await BlogService.saveBlog(
        id: widget.postData?['id'],
        title: _titleController.text,
        content: _contentController.text,
        webImage: _webImage, 
        existingImageUrl: _existingImageUrl,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.postData == null ? "Posted!" : "Updated!")),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String screenTitle = widget.postData == null ? "Create New Post" : "Edit Post";

    return AppScaffold(
      title: screenTitle,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  image: _webImage != null
                      ? DecorationImage(image: MemoryImage(_webImage!), fit: BoxFit.cover)
                      : (_existingImageUrl != null
                          ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                          : null),
                ),
                child: (_webImage == null && _existingImageUrl == null)
                    ? const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey))
                    : null,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Blog Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(labelText: "Content", border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSave,
                icon: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(widget.postData == null ? "Publish Blog" : "Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}