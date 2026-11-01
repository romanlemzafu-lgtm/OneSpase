import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/local_post.dart';
import '../theme/onespase_theme.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _post = TextEditingController();

  @override
  void dispose() {
    _post.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/onespase_icon.png',
                    width: 34,
                    height: 34,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'OneSpase',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Поиск',
                  onPressed: () {},
                  icon: const Icon(Icons.search_rounded),
                ),
                const SizedBox(width: 6),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Avatar(label: widget.controller.userName ?? 'O'),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _post,
                                minLines: 2,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  hintText: 'Что нового в твоём пространстве?',
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              color: OneSpaseTheme.accent,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Фото',
                              style: TextStyle(
                                color: OneSpaseTheme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: _publish,
                              child: const Text('Опубликовать'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
              sliver: SliverList.separated(
                itemCount: widget.controller.posts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final post = widget.controller.posts[index];
                  return _PostCard(
                    post: post,
                    onLike: () => widget.controller.toggleLike(post),
                    onComment: () => _comment(post),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _publish() async {
    if (_post.text.trim().isEmpty) return;
    final text = _post.text;
    _post.clear();
    await widget.controller.addPost(text);
  }

  Future<void> _comment(LocalPost post) async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: OneSpaseTheme.surface,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Комментарий',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Напиши ответ...'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Отправить'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (result != null) await widget.controller.addComment(post, result);
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
  });

  final LocalPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(label: post.author),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _timeAgo(post.createdAt),
                        style: const TextStyle(
                          color: OneSpaseTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded),
              ],
            ),
            const SizedBox(height: 14),
            Text(post.text, style: const TextStyle(fontSize: 16, height: 1.4)),
            if (post.comments.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OneSpaseTheme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  post.comments.last,
                  style: const TextStyle(
                    color: OneSpaseTheme.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _ActionChip(
                  icon: post.likedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: '${post.likes}',
                  active: post.likedByMe,
                  onTap: onLike,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.comments.length}',
                  onTap: onComment,
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  icon: Icons.ios_share_outlined,
                  label: 'Поделиться',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    if (diff.inHours < 24) return '${diff.inHours} ч';
    return '${diff.inDays} дн';
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? OneSpaseTheme.accentSoft : OneSpaseTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active
                  ? OneSpaseTheme.accent
                  : OneSpaseTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 23,
      backgroundColor: OneSpaseTheme.accentSoft,
      child: Text(
        text,
        style: const TextStyle(
          color: OneSpaseTheme.accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
