import 'package:blogs/pages/blogs/create_blog_screen.dart';
import 'package:blogs/services/auth_services.dart';
import 'package:blogs/services/blog_services.dart';
import 'package:blogs/widgets/blogs_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/comment/comment_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _formatTimeAgo(String timestamp) {
    DateTime postDate = DateTime.parse(timestamp);
    Duration diff = DateTime.now().difference(postDate);
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Home",
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/create-blog'),
        child: const Icon(Icons.add),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('blog_with_profile')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No blogs yet. Be the first to post!"));
          }

          final posts = snapshot.data!.reversed.toList(); 

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postCount = post['comment_count'];
              final imageUrl = post['image_url'];

              final currentUserId = AuthService().currentUserId;
              final bool isOwner = post['user_id'] == currentUserId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.grey[200],
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (post['user_avatar'] != null && post['user_avatar'].toString().isNotEmpty)
                            ? NetworkImage(post['user_avatar'])
                            : null,
                        child: (post['user_avatar'] == null || post['user_avatar'].toString().isEmpty)
                            ? Text(
                                (post['user_name'] ?? "U")[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(
                        post['user_name'] ?? "Unknown Author",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(_formatTimeAgo(post['created_at'])),
                      trailing: isOwner 
                      ? IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => BlogDialogs.showOptions(
                            context,
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateBlogScreen(postData: post),
                                ),
                              );
                            },
                            onDelete: () async {
                              bool confirm = await BlogDialogs.showDeleteDialog(context, "Post");
                              if (confirm) await BlogService.deleteRecord('blogs', post['id']);
                            },
                          ),
                        )
                      : null,
                    ),

                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post['title'] ?? "Untitled",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(post['content'] ?? ""),
                        ],
                      ),
                    ),
                    Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TextButton.icon(
                        onPressed: () => CommentSheet.show(context, post['id']), 
                        icon: const Icon(Icons.comment_outlined),
                        label: Text(
                          (postCount > 0) 
                              ? "$postCount Comments" 
                              : "Comments",
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}