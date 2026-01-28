import 'package:flutter/material.dart';

class CommentItem extends StatelessWidget {
  final Map<String, dynamic> comm;
  final bool isOwner;
  final bool isEditing; 
  final Function(Map<String, dynamic>) onEdit;
  final Function(String) onDelete;
  final String Function(String) formatTime;

  const CommentItem({
    super.key, 
    required this.comm,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
    required this.formatTime,
    this.isEditing = false, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isEditing ? Colors.blue.shade100 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: comm['user_avatar'] != null 
              ? NetworkImage(comm['user_avatar']) 
              : null,
          child: comm['user_avatar'] == null 
              ? Text((comm['user_name'] ?? "U")[0].toUpperCase()) 
              : null,
        ),
        title: Text(
          comm['user_name'] ?? "User", 
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              comm['content'] ?? "",
              style: TextStyle(
                color: isEditing ? Colors.blue[900] : Colors.black87,
                fontWeight: isEditing ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (comm['image_url'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    comm['image_url'], 
                    height: 150, 
                    width: double.infinity, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              formatTime(comm['created_at']), 
              style: TextStyle(fontSize: 10, color: Colors.grey[500])
            ),
          ],
        ),
        trailing: isOwner 
        ? PopupMenuButton<String>(
            padding: const EdgeInsets.all(8), 
            icon: const Icon(Icons.more_vert, size: 24), 
            onSelected: (value) {

              if (value == 'edit') {
                onEdit(comm);
              } else if (value == 'delete') {
                onDelete(comm['id'].toString());
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit', 
                child: Row(
                  children: const [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 10),
                    Text("Edit"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete', 
                child: Row(
                  children: const [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text("Delete", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ) 
        : null,
      ),
    );
  }
}