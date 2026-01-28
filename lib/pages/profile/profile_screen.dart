import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final bool isSetupMode;
  const ProfileScreen({super.key, this.isSetupMode = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  File? _avatarFile;
  String? _avatarUrl; 
  bool _isLoading = false;

  final String _userId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _userId)
          .maybeSingle();

      if (profileData != null) {
        setState(() {
          _nameController.text = profileData['display_name'] ?? "";
          _avatarUrl = profileData['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_avatarFile == null) return _avatarUrl; 

    final fileExtension = _avatarUrl!.split(".").last;
    final fileName = '$_userId-avatar-${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
    
    await Supabase.instance.client.storage.from('profiles').upload(
          fileName,
          _avatarFile!,
          fileOptions: const FileOptions(upsert: true),
        );

    return Supabase.instance.client.storage.from('profiles').getPublicUrl(fileName);
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your display name")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final finalAvatarUrl = await _uploadAvatar();

      await Supabase.instance.client.from('profiles').upsert({
        'id': _userId,
        'display_name': _nameController.text.trim(),
        'avatar_url': finalAvatarUrl,
      });

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'has_profile': true}),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Saved!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetupMode ? "Setup Profile" : "Edit Profile"),
        automaticallyImplyLeading: !widget.isSetupMode,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    backgroundImage: _avatarFile != null
                        ? FileImage(_avatarFile!)
                        : (_avatarUrl != null ? NetworkImage(_avatarUrl!) : null) as ImageProvider?,
                    child: (_avatarFile == null && _avatarUrl == null)
                        ? const Icon(Icons.person, size: 50, color: Colors.blue)
                        : null,
                  ),
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Display Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Save and Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}