import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/premium_dialog.dart';
import '../../providers/providers.dart';
import '../../../domain/models/domain_models.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  @override
  Widget build(BuildContext context) {
    final activeEntre = ref.watch(currentEntrepreneurProvider);
    final posts = ref.watch(communityPostsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    String getInitials(String name) {
      if (name.isEmpty) return "Q";
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }

    if (activeEntre == null) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.darkPrimaryGold)),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('FOUNDER NETWORK'),
        backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Announcement banner
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 12,
                child: Row(
                  children: [
                    const Text('📢', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FOUNDER COHORT SUMMIT 2026',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkPrimaryGold, letterSpacing: 1),
                          ),
                          Text(
                            'Live roundtable with Qaafiya partners scheduled for June 25, 4:00 PM IST.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            // Posts list feed
            Expanded(
              child: posts.isEmpty
                  ? const Center(child: Text('Founder feed is empty.'))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Author details
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            isDark ? Colors.grey[800]! : Colors.grey[300]!,
                                            isDark ? Colors.grey[700]! : Colors.grey[200]!,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        border: Border.all(
                                          color: (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          getInitials(post.authorName),
                                          style: TextStyle(
                                            color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.authorName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            post.authorBusiness,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      DateFormat('dd MMM').format(DateTime.parse(post.createdAt)),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                // Title & Content
                                Text(
                                  post.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkPrimaryGold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  post.content,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                                  ),
                                ),
                                const Divider(height: 24),
                                // Like & comments counter
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // Update like count in Isar
                                        ref.read(communityPostsProvider.notifier).save(
                                          post.copyWith(likes: post.likes + 1),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.arrow_upward_rounded, size: 16, color: AppTheme.darkPrimaryGold),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${post.likes} UPVOTES',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkPrimaryGold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Row(
                                      children: [
                                        const Icon(Icons.mode_comment_outlined, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${post.comments} DISCUSSIONS',
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    // Delete button for demo CRUD purposes
                                    IconButton(
                                      onPressed: () {
                                        PremiumDialog.show(
                                          context: context,
                                          title: "Delete Feed Update?",
                                          icon: Icons.delete_forever_rounded,
                                          iconColor: AppTheme.colorError,
                                          content: Text(
                                            "Are you sure you want to permanently delete this update from your community feed?",
                                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('CANCEL'),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorError),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                ref.read(communityPostsProvider.notifier).delete(post.id);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Update removed from feed.')),
                                                );
                                              },
                                              child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                            ),
                                          ],
                                        );
                                      },
                                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context, activeEntre),
        backgroundColor: isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold,
        foregroundColor: isDark ? AppTheme.darkBackground : Colors.white,
        child: const Icon(Icons.rate_review_outlined),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context, Entrepreneur activeEntre) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Post Success Story or Update'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Headline Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Body Content details...'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out all fields.')),
                  );
                  return;
                }

                final newPost = CommunityPost(
                  id: 'P-COM-${DateTime.now().millisecond}',
                  authorName: activeEntre.name,
                  authorBusiness: activeEntre.businessName,
                  authorAvatar: activeEntre.avatar,
                  title: titleController.text,
                  content: contentController.text,
                  likes: 1,
                  comments: 0,
                  createdAt: DateTime.now().toIso8601String(),
                );

                ref.read(communityPostsProvider.notifier).save(newPost);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully posted to Elite network!')),
                );
              },
              child: const Text('POST'),
            ),
          ],
        );
      },
    );
  }
}
