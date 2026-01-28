import 'package:flutter/material.dart';

class BlogDialogs {
  static Future<bool> showDeleteDialog(BuildContext context, String type) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete $type?"),
            content: Text("Are you sure you want to delete?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;
  }

  static void showOptions(BuildContext context, {required VoidCallback onEdit, required VoidCallback onDelete}) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Post'),
              onTap: () { Navigator.pop(context); onEdit(); },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
              onTap: () { Navigator.pop(context); onDelete(); },
            ),
          ],
        ),
      ),
    );
  }
}