import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'models/models.dart';
import 'services/local_repository.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(LocalRepository());
  await controller.load();
  runApp(OneSpaseApp(controller: controller));
}

class OneSpaseApp extends StatelessWidget {
  const OneSpaseApp({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OneSpase',
        theme: OneSpaseTheme.dark(),
        home: HomeShell(controller: controller),
      );
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      FeedScreen(controller: widget.controller),
      ChatsScreen(controller: widget.controller),
      PeopleScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
    ];
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) => Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (v) => setState(() => index = v),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dynamic_feed_outlined), selectedIcon: Icon(Icons.dynamic_feed_rounded), label: 'Лента'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'Чаты'),
            NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Люди'),
            NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Профиль'),
          ],
        ),
      ),
    );
  }
}

Color themeColor(String theme) => switch (theme) {
      'blue' => const Color(0xFF4C8DFF),
      'sunset' => const Color(0xFFFF7A45),
      'mint' => const Color(0xFF48D6AD),
      'aurora' => const Color(0xFF42E6C6),
      'midnight' => const Color(0xFF8B7CFF),
      'gold' => const Color(0xFFFFC857),
      _ => OneSpaseTheme.accent,
    };

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.type, this.size = 18});
  final String type;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (type == 'none') return const SizedBox.shrink();
    final color = type == 'red' ? const Color(0xFFFF4D61) : type == 'purple' ? OneSpaseTheme.accent : const Color(0xFF4C9AFF);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(Icons.check_rounded, color: Colors.white, size: size * .72),
    );
  }
}

class OneSpasePlusBadge extends StatelessWidget {
  const OneSpasePlusBadge({super.key, this.compact = true});
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 8, vertical: compact ? 2 : 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9D6CFF), Color(0xFFFFC857)]),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: compact ? 11 : 14),
          if (!compact) ...[
            const SizedBox(width: 4),
            const Text('PLUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
          ],
        ]),
      );
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 24});
  final UserProfile user;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: themeColor(user.theme).withOpacity(.22),
      child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: radius * .85, color: themeColor(user.theme))),
    );
    if (!user.plus) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF9D6CFF), Color(0xFF42E6C6), Color(0xFFFFC857)]),
      ),
      child: avatar,
    );
  }
}

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key, required this.controller});
  final AppController controller;

  Future<void> _newPost(BuildContext context) async {
    final c = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: OneSpaseTheme.surface,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(context).viewInsets.bottom + 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Новая публикация', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextField(controller: c, minLines: 3, maxLines: 7, autofocus: true, decoration: const InputDecoration(hintText: 'Что нового?')),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async { await controller.createPost(c.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Опубликовать'))),
        ]),
      ),
    );
    c.dispose();
  }

  Future<void> _newStory(BuildContext context) async {
    final c = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Новая Story'),
        content: TextField(controller: c, maxLength: 120, decoration: const InputDecoration(hintText: 'Текст истории')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () async { final err = await controller.createStory(c.text); if (!context.mounted) return; if (err == null) { Navigator.pop(context); } else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err))); } }, child: const Text('Создать')),
        ],
      ),
    );
    c.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, __) => CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('OneSpase', style: TextStyle(fontWeight: FontWeight.w900)),
              actions: [
                IconButton(onPressed: () => _newStory(context), icon: const Icon(Icons.add_circle_outline_rounded), tooltip: 'Создать Story'),
                IconButton(onPressed: () => _newPost(context), icon: const Icon(Icons.edit_square), tooltip: 'Создать пост'),
              ],
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 104,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  children: [
                    InkWell(
                      onTap: () => _newStory(context),
                      borderRadius: BorderRadius.circular(40),
                      child: const SizedBox(width: 76, child: Column(children: [CircleAvatar(radius: 30, backgroundColor: OneSpaseTheme.raised, child: Icon(Icons.add_rounded)), SizedBox(height: 5), Text('Добавить', style: TextStyle(fontSize: 11))])),
                    ),
                    ...controller.liveStories.map((s) {
                      final u = controller.userById(s.authorId);
                      return InkWell(
                        onTap: () => showDialog(context: context, builder: (_) => StoryDialog(controller: controller, story: s)),
                        child: SizedBox(width: 78, child: Column(children: [
                          Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [OneSpaseTheme.accent, Color(0xFF4C8DFF)])), child: UserAvatar(user: u, radius: 28)),
                          const SizedBox(height: 5), Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                        ])),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
              sliver: SliverList.builder(
                itemCount: controller.posts.length,
                itemBuilder: (_, i) => PostCard(controller: controller, post: controller.posts[i]),
              ),
            ),
          ],
        ),
      );
}

class StoryDialog extends StatelessWidget {
  const StoryDialog({super.key, required this.controller, required this.story});
  final AppController controller;
  final StoryItem story;
  @override
  Widget build(BuildContext context) {
    final u = controller.userById(story.authorId);
    return Dialog(
      backgroundColor: const Color(0xFF111219),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(colors: [themeColor(u.theme).withOpacity(.45), const Color(0xFF111219)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [UserAvatar(user: u), const SizedBox(width: 10), Expanded(child: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w900))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
          const Spacer(),
          Center(child: Text(story.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
          const Spacer(),
          if (story.authorId == controller.me.id) Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(onPressed: () => controller.toggleStoryPin(story.id), icon: Icon(story.pinned ? Icons.push_pin : Icons.push_pin_outlined), label: Text(story.pinned ? 'Открепить' : 'Закрепить')),
            TextButton.icon(onPressed: () async { await controller.deleteStory(story.id); if (context.mounted) Navigator.pop(context); }, icon: const Icon(Icons.delete_outline), label: const Text('Удалить')),
          ]),
        ]),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.controller, required this.post});
  final AppController controller;
  final PostItem post;
  @override
  Widget build(BuildContext context) {
    final u = controller.userById(post.authorId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            UserAvatar(user: u), const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w900))), const SizedBox(width: 5), VerificationBadge(type: u.verification), if(u.plus) const Padding(padding:EdgeInsets.only(left:5),child:OneSpasePlusBadge())]), Text('@${u.username}', style: const TextStyle(color: OneSpaseTheme.secondary, fontSize: 12))])),
            if (post.authorId == controller.me.id) PopupMenuButton<String>(onSelected: (v) { if (v == 'delete') controller.deletePost(post.id); }, itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Удалить'))]),
          ]),
          const SizedBox(height: 14), Text(post.text, style: const TextStyle(fontSize: 16, height: 1.4)),
          const SizedBox(height: 14),
          Row(children: [
            IconButton(onPressed: () => controller.toggleLike(post.id), icon: Icon(post.liked ? Icons.favorite : Icons.favorite_border, color: post.liked ? const Color(0xFFFF5D73) : null)), Text('${post.likes}'),
            IconButton(onPressed: () => controller.addComment(post.id), icon: const Icon(Icons.mode_comment_outlined)), Text('${post.comments}'),
            const Spacer(),
            IconButton(onPressed: () => controller.toggleSavedPost(post.id), icon: Icon(post.saved ? Icons.bookmark : Icons.bookmark_border)),
          ]),
        ]),
      ),
    );
  }
}

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String folder = 'Все';
  bool showArchive = false;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (_, __) {
          var list = widget.controller.chats.where((c) => c.archived == showArchive).toList();
          if (folder != 'Все') {
            final kind = folder == 'Личные' ? 'personal' : folder == 'Группы' ? 'group' : folder == 'Каналы' ? 'channel' : 'saved';
            list = list.where((c) => c.kind == kind).toList();
          }
          list.sort((a,b) => (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0));
          return Scaffold(
            appBar: AppBar(
              title: Text(showArchive ? 'Архив' : 'Чаты', style: const TextStyle(fontWeight: FontWeight.w900)),
              actions: [IconButton(onPressed: () => setState(() => showArchive = !showArchive), icon: Icon(showArchive ? Icons.inbox_outlined : Icons.archive_outlined))],
            ),
            body: Column(children: [
              SizedBox(height: 48, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: ['Все','Личные','Группы','Каналы','Избранное'].map((f) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(f), selected: folder == f, onSelected: (_) => setState(() => folder = f)))).toList())),
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final c = list[i];
                  final last = c.messages.isEmpty ? 'Сообщений пока нет' : c.messages.last.text;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(backgroundColor: OneSpaseTheme.raised, child: Icon(c.kind == 'saved' ? Icons.bookmark_rounded : c.kind == 'group' ? Icons.groups_rounded : c.kind == 'channel' ? Icons.campaign_rounded : Icons.person_rounded)),
                      title: Row(children: [Expanded(child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w800))), if (c.pinned) const Icon(Icons.push_pin_rounded, size: 15), if (c.muted) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.notifications_off_rounded, size: 15))]),
                      subtitle: Text(c.draft.isNotEmpty ? 'Черновик: ${c.draft}' : last, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.draft.isNotEmpty ? OneSpaseTheme.accent : OneSpaseTheme.secondary)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) { if(v=='pin') widget.controller.togglePinChat(c.id); if(v=='archive') widget.controller.toggleArchive(c.id); if(v=='mute') widget.controller.toggleMute(c.id); },
                        itemBuilder: (_) => [PopupMenuItem(value:'pin', child: Text(c.pinned?'Открепить':'Закрепить')), PopupMenuItem(value:'archive', child: Text(c.archived?'Вернуть из архива':'В архив')), PopupMenuItem(value:'mute', child: Text(c.muted?'Включить звук':'Без звука'))],
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(controller: widget.controller, chatId: c.id))),
                    ),
                  );
                },
              )),
            ]),
          );
        },
      );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.controller, required this.chatId});
  final AppController controller;
  final String chatId;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final TextEditingController input;
  String? replyTo;
  @override
  void initState() { super.initState(); input = TextEditingController(text: widget.controller.chatById(widget.chatId).draft); input.addListener(() => widget.controller.setDraft(widget.chatId, input.text)); }
  @override
  void dispose() { input.dispose(); super.dispose(); }

  Future<void> _searchMessages() async {
    final query = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) {
          final chat = widget.controller.chatById(widget.chatId);
          final q = query.text.trim().toLowerCase();
          final results = q.isEmpty
              ? <ChatMessage>[]
              : chat.messages.where((m) => m.text.toLowerCase().contains(q)).toList();
          return AlertDialog(
            title: const Text('Поиск в чате'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: query,
                    autofocus: true,
                    onChanged: (_) => setDialog(() {}),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Текст сообщения'),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(results[i].text, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${results[i].sentAt.hour.toString().padLeft(2, '0')}:${results[i].sentAt.minute.toString().padLeft(2, '0')}'),
                      ),
                    ),
                  ),
                  if (q.isNotEmpty && results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Ничего не найдено', style: TextStyle(color: OneSpaseTheme.secondary)),
                    ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Готово'))],
          );
        },
      ),
    );
    query.dispose();
  }

  Future<void> _edit(ChatMessage m) async {
    final c = TextEditingController(text: m.text);
    await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Редактировать сообщение'), content: TextField(controller:c, autofocus:true), actions:[TextButton(onPressed:()=>Navigator.pop(context), child:const Text('Отмена')), FilledButton(onPressed:() async { await widget.controller.editMessage(widget.chatId, m.id, c.text); if(context.mounted) Navigator.pop(context); }, child:const Text('Сохранить'))]));
    c.dispose();
  }

  Future<void> _pickReaction(ChatMessage m) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Expanded(child: Text('Выбери реакцию', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
              if (widget.controller.isPlus) const OneSpasePlusBadge(compact: false),
            ]),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.controller.availableReactions.map((r) => InkWell(
                onTap: () async { await widget.controller.react(widget.chatId, m.id, r); if (context.mounted) Navigator.pop(context); },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: OneSpaseTheme.raised, borderRadius: BorderRadius.circular(16)),
                  child: Text(r, style: const TextStyle(fontSize: 27)),
                ),
              )).toList(),
            ),
            if (!widget.controller.isPlus) ...[
              const SizedBox(height: 14),
              const Text('OneSpase Plus открывает ещё 5 реакций.', style: TextStyle(color: OneSpaseTheme.secondary)),
            ],
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (_, __) {
          final chat = widget.controller.chatById(widget.chatId);
          return Scaffold(
            appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(chat.title, style: const TextStyle(fontWeight: FontWeight.w900)), const Text('локальный чат', style: TextStyle(fontSize:11, color:OneSpaseTheme.secondary))]), actions:[IconButton(onPressed:_searchMessages, icon:const Icon(Icons.search_rounded), tooltip:'Поиск в чате')]),
            body: Column(children: [
              Expanded(child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: chat.messages.length,
                itemBuilder: (_, i) {
                  final m = chat.messages[i]; final mine = m.senderId == widget.controller.me.id;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: () => showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Wrap(children:[
                        ListTile(leading:const Icon(Icons.reply), title:const Text('Ответить'), onTap:(){Navigator.pop(context); setState(()=>replyTo=m.id);}),
                        ListTile(leading:const Icon(Icons.add_reaction_outlined), title:const Text('Реакция'), onTap:(){Navigator.pop(context); _pickReaction(m);}),
                        if(mine) ListTile(leading:const Icon(Icons.edit_outlined), title:const Text('Редактировать'), onTap:(){Navigator.pop(context); _edit(m);}),
                        if(mine) ListTile(leading:const Icon(Icons.delete_outline), title:const Text('Удалить'), onTap:(){Navigator.pop(context); widget.controller.deleteMessage(chat.id,m.id);}),
                      ]))),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
                        margin: const EdgeInsets.symmetric(vertical:4), padding: const EdgeInsets.symmetric(horizontal:14, vertical:10),
                        decoration: BoxDecoration(color: mine ? OneSpaseTheme.accent.withOpacity(.85) : OneSpaseTheme.surface, borderRadius: BorderRadius.circular(18)),
                        child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                          if(m.replyTo!=null) const Text('↪ ответ на сообщение', style:TextStyle(fontSize:11, color:Colors.white70)),
                          Text(m.text),
                          Row(mainAxisSize:MainAxisSize.min, children:[if(m.edited) const Text('изменено · ', style:TextStyle(fontSize:10,color:Colors.white70)), Text('${m.sentAt.hour.toString().padLeft(2,'0')}:${m.sentAt.minute.toString().padLeft(2,'0')}', style:const TextStyle(fontSize:10,color:Colors.white70)), if(m.reaction.isNotEmpty) Padding(padding:const EdgeInsets.only(left:8), child:Text(m.reaction))]),
                        ]),
                      ),
                    ),
                  );
                },
              )),
              if(replyTo!=null) Container(color:OneSpaseTheme.surface, padding:const EdgeInsets.symmetric(horizontal:12), child:Row(children:[const Expanded(child:Text('Ответ на сообщение')), IconButton(onPressed:()=>setState(()=>replyTo=null), icon:const Icon(Icons.close))])),
              SafeArea(top:false, child: Padding(padding: const EdgeInsets.fromLTRB(10,8,10,8), child: Row(children:[
                Expanded(child:TextField(controller:input, minLines:1, maxLines:5, decoration:const InputDecoration(hintText:'Сообщение'))),
                const SizedBox(width:8),
                IconButton.filled(onPressed:() async { final text=input.text; input.clear(); await widget.controller.sendMessage(chat.id,text,replyTo:replyTo); if(mounted)setState(()=>replyTo=null); }, icon:const Icon(Icons.send_rounded)),
              ]))),
            ]),
          );
        },
      );
}

class PeopleScreen extends StatelessWidget {
  const PeopleScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Люди', style: TextStyle(fontWeight: FontWeight.w900))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12,8,12,100),
            children: controller.users.where((u)=>u.id!=controller.me.id).map((u)=>Card(child:ListTile(
              contentPadding:const EdgeInsets.all(12), leading:UserAvatar(user:u),
              title:Row(children:[Flexible(child:Text(u.name,style:const TextStyle(fontWeight:FontWeight.w900))),const SizedBox(width:5),VerificationBadge(type:u.verification),if(u.plus) const Padding(padding:EdgeInsets.only(left:5),child:OneSpasePlusBadge()),if(u.emojiStatus.isNotEmpty) Padding(padding:const EdgeInsets.only(left:5),child:Text(u.emojiStatus))]),
              subtitle:Text('@${u.username} · ${u.status}',style:const TextStyle(color:OneSpaseTheme.secondary)),
              trailing:IconButton(onPressed:()=>controller.follow(u.id),icon:Icon(u.following?Icons.person_remove_alt_1:Icons.person_add_alt_1)),
              onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PublicProfileScreen(controller:controller,userId:u.id))),
            ))).toList(),
          ),
        ),
      );
}

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, required this.controller, required this.userId});
  final AppController controller; final String userId;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:controller,builder:(_,__) {
    final u=controller.userById(userId); final accent=themeColor(u.theme);
    return Scaffold(appBar:AppBar(title:Text(u.name)),body:ListView(padding:const EdgeInsets.all(14),children:[
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(30),gradient:LinearGradient(colors:[accent.withOpacity(.35),OneSpaseTheme.surface])),child:Column(children:[UserAvatar(user:u,radius:52),const SizedBox(height:12),Row(mainAxisAlignment:MainAxisAlignment.center,children:[Text(u.name,style:const TextStyle(fontSize:25,fontWeight:FontWeight.w900)),const SizedBox(width:6),VerificationBadge(type:u.verification,size:22),if(u.plus) const Padding(padding:EdgeInsets.only(left:6),child:OneSpasePlusBadge()),if(u.emojiStatus.isNotEmpty) Padding(padding:const EdgeInsets.only(left:6),child:Text(u.emojiStatus,style:const TextStyle(fontSize:21)))]),Text('@${u.username}',style:const TextStyle(color:OneSpaseTheme.secondary)),const SizedBox(height:8),Text(u.bio,textAlign:TextAlign.center)])),
      const SizedBox(height:12),
      Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>_openOrCreateChat(context,u),icon:const Icon(Icons.chat_bubble_outline),label:const Text('Написать'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:()=>_gift(context,u),icon:const Icon(Icons.card_giftcard),label:const Text('Подарок')))]),
      const SizedBox(height:8),
      Row(children:[Expanded(child:OutlinedButton(onPressed:()=>controller.follow(u.id),child:Text(u.following?'Отписаться':'Подписаться'))),const SizedBox(width:8),Expanded(child:OutlinedButton(onPressed:()=>controller.block(u.id),child:Text(u.blocked?'Разблокировать':'Заблокировать')))]),
      if(u.music.isNotEmpty)...[const SizedBox(height:14),Card(child:ListTile(leading:const Icon(Icons.music_note),title:Text(u.music),subtitle:const Text('Музыка профиля')))],
    ]));
  });
  void _openOrCreateChat(BuildContext context,UserProfile u){
    final existing=controller.chats.where((c)=>c.peerId==u.id&&c.kind=='personal').toList();
    final chat=existing.isNotEmpty?existing.first:ChatThread(id:'chat_${DateTime.now().microsecondsSinceEpoch}',title:u.name,kind:'personal',peerId:u.id);
    if(existing.isEmpty){controller.chats.add(chat);controller.save();}
    Navigator.push(context,MaterialPageRoute(builder:(_)=>ChatScreen(controller:controller,chatId:chat.id)));
  }
  Future<void> _gift(BuildContext context,UserProfile u) async {
    final note=TextEditingController();
    await showModalBottomSheet(context:context,isScrollControlled:true,builder:(_)=>Padding(padding:EdgeInsets.fromLTRB(18,18,18,MediaQuery.of(context).viewInsets.bottom+18),child:Column(mainAxisSize:MainAxisSize.min,children:[const SecretPacketGift(size:150),const Text('Секретный пакетик',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const Text('Rare · Никто не знает, что в нём. И, возможно, не узнает.',textAlign:TextAlign.center,style:TextStyle(color:OneSpaseTheme.secondary)),const SizedBox(height:12),TextField(controller:note,decoration:const InputDecoration(labelText:'Сообщение к подарку')),const SizedBox(height:12),SizedBox(width:double.infinity,child:FilledButton(onPressed:() async {await controller.sendSecretPacket(u.id,note:note.text);if(context.mounted){Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Подарок отправлен')));}},child:const Text('Подарить')))])));
    note.dispose();
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation:controller,builder:(_,__) {
    final me=controller.me; final accent=themeColor(me.theme);
    return CustomScrollView(slivers:[
      SliverAppBar(floating:true,title:const Text('Профиль',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SettingsScreen(controller:controller))),icon:const Icon(Icons.settings_outlined))]),
      SliverPadding(padding:const EdgeInsets.fromLTRB(14,8,14,110),sliver:SliverList(delegate:SliverChildListDelegate([
        Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(borderRadius:BorderRadius.circular(30),gradient:LinearGradient(colors:[accent.withOpacity(.36),OneSpaseTheme.surface],begin:Alignment.topLeft,end:Alignment.bottomRight)),child:Column(children:[UserAvatar(user:me,radius:56),const SizedBox(height:12),Row(mainAxisAlignment:MainAxisAlignment.center,children:[Flexible(child:Text(me.name,style:const TextStyle(fontSize:26,fontWeight:FontWeight.w900))),const SizedBox(width:6),VerificationBadge(type:me.verification,size:23),if(me.plus) const Padding(padding:EdgeInsets.only(left:6),child:OneSpasePlusBadge()),if(me.emojiStatus.isNotEmpty) Padding(padding:const EdgeInsets.only(left:6),child:Text(me.emojiStatus,style:const TextStyle(fontSize:22)))]),Text('@${me.username}',style:const TextStyle(color:OneSpaseTheme.secondary)),const SizedBox(height:5),Text(me.status,style:TextStyle(color:accent,fontWeight:FontWeight.w700)),if(me.music.isNotEmpty)...[const SizedBox(height:10),Chip(avatar:const Icon(Icons.music_note_rounded,size:17),label:Text(me.music))]])),
        const SizedBox(height:12),
        Row(children:[Expanded(child:_ProfileAction(icon:Icons.edit_outlined,label:'Редактировать',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>EditProfileScreen(controller:controller))))),const SizedBox(width:8),Expanded(child:_ProfileAction(icon:Icons.card_giftcard,label:'Подарки',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>GiftsScreen(controller:controller))))),const SizedBox(width:8),Expanded(child:_ProfileAction(icon:Icons.qr_code_rounded,label:'QR',onTap:()=>showDialog(context:context,builder:(_)=>QrDialog(username:me.username))))]),
        const SizedBox(height:12),
        Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('О себе',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:7),Text(me.bio),if(me.channel.isNotEmpty)...[const SizedBox(height:12),Text('📣 @${me.channel}',style:const TextStyle(fontWeight:FontWeight.w800))]]))),
        const SizedBox(height:12),
        Row(children:[Expanded(child:_Stat('${controller.myPosts.length}','публикаций')),const SizedBox(width:8),Expanded(child:_Stat('${controller.myGifts.length}','подарков')),const SizedBox(width:8),Expanded(child:_Stat('${controller.emojiPacks.length}','emoji-паков'))]),
        const SizedBox(height:12),
        DefaultTabController(length:3,child:Column(children:[const TabBar(tabs:[Tab(text:'Публикации'),Tab(text:'Подарки'),Tab(text:'Медиа')]),SizedBox(height:340,child:TabBarView(children:[
          ListView(children:controller.myPosts.map((p)=>PostCard(controller:controller,post:p)).toList()),
          GridView.builder(padding:const EdgeInsets.only(top:12),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.82,crossAxisSpacing:10,mainAxisSpacing:10),itemCount:controller.myGifts.length,itemBuilder:(_,i)=>GiftTile(controller:controller,gift:controller.myGifts[i])),
          const Center(child:Text('Медиа появятся здесь',style:TextStyle(color:OneSpaseTheme.secondary))),
        ]))])),
      ])))
    ]);
  });
}

class _ProfileAction extends StatelessWidget { const _ProfileAction({required this.icon,required this.label,required this.onTap}); final IconData icon; final String label; final VoidCallback onTap; @override Widget build(BuildContext context)=>Material(color:OneSpaseTheme.surface,borderRadius:BorderRadius.circular(20),child:InkWell(borderRadius:BorderRadius.circular(20),onTap:onTap,child:Padding(padding:const EdgeInsets.symmetric(vertical:15,horizontal:5),child:Column(children:[Icon(icon),const SizedBox(height:5),Text(label,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800),textAlign:TextAlign.center)])))); }
class _Stat extends StatelessWidget { const _Stat(this.value,this.label); final String value,label; @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.symmetric(vertical:14),child:Column(children:[Text(value,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(fontSize:10,color:OneSpaseTheme.secondary))]))); }

class EditProfileScreen extends StatefulWidget { const EditProfileScreen({super.key,required this.controller}); final AppController controller; @override State<EditProfileScreen> createState()=>_EditProfileScreenState(); }
class _EditProfileScreenState extends State<EditProfileScreen>{ late final TextEditingController n,u,b,s; String? error; @override void initState(){super.initState();final me=widget.controller.me;n=TextEditingController(text:me.name);u=TextEditingController(text:me.username);b=TextEditingController(text:me.bio);s=TextEditingController(text:me.status);} @override void dispose(){n.dispose();u.dispose();b.dispose();s.dispose();super.dispose();} @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Редактировать профиль')),body:ListView(padding:const EdgeInsets.all(14),children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Имя')),const SizedBox(height:10),TextField(controller:u,decoration:const InputDecoration(labelText:'Username',prefixText:'@')),const SizedBox(height:10),TextField(controller:b,maxLines:4,decoration:const InputDecoration(labelText:'О себе')),const SizedBox(height:10),TextField(controller:s,decoration:const InputDecoration(labelText:'Статус')),if(error!=null)Padding(padding:const EdgeInsets.only(top:10),child:Text(error!,style:const TextStyle(color:Colors.redAccent))),const SizedBox(height:14),FilledButton(onPressed:()async{final e=await widget.controller.updateProfile(name:n.text,username:u.text,bio:b.text,status:s.text);if(e!=null){setState(()=>error=e);}else if(context.mounted)Navigator.pop(context);},child:const Text('Сохранить'))])); }

class GiftsScreen extends StatelessWidget { const GiftsScreen({super.key,required this.controller}); final AppController controller; @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(_,__)=>Scaffold(appBar:AppBar(title:const Text('Подарки')),body:ListView(padding:const EdgeInsets.all(14),children:[Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[const SecretPacketGift(size:185),const Text('Секретный пакетик',style:TextStyle(fontSize:24,fontWeight:FontWeight.w900)),const Text('Rare',style:TextStyle(color:Color(0xFF7EB6FF),fontWeight:FontWeight.w800)),const SizedBox(height:5),const Text('Никто не знает, что в нём. И, возможно, не узнает.',textAlign:TextAlign.center,style:TextStyle(color:OneSpaseTheme.secondary)),const SizedBox(height:12),FilledButton.icon(onPressed:()=>_chooseReceiver(context),icon:const Icon(Icons.card_giftcard),label:const Text('Подарить'))]))),const SizedBox(height:14),const Text('Моя коллекция',style:TextStyle(fontSize:19,fontWeight:FontWeight.w900)),const SizedBox(height:8),GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:.82,crossAxisSpacing:10,mainAxisSpacing:10),itemCount:controller.myGifts.length,itemBuilder:(_,i)=>GiftTile(controller:controller,gift:controller.myGifts[i]))]))); Future<void> _chooseReceiver(BuildContext context)async{await showModalBottomSheet(context:context,builder:(_)=>SafeArea(child:ListView(shrinkWrap:true,children:controller.users.where((u)=>u.id!=controller.me.id).map((u)=>ListTile(leading:UserAvatar(user:u),title:Text(u.name),subtitle:Text('@${u.username}'),onTap:()async{await controller.sendSecretPacket(u.id);if(context.mounted){Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('«Секретный пакетик» отправлен ${u.name}')));}})).toList())));}}

class GiftTile extends StatelessWidget { const GiftTile({super.key,required this.controller,required this.gift}); final AppController controller; final GiftInstance gift; @override Widget build(BuildContext context)=>Card(child:InkWell(borderRadius:BorderRadius.circular(24),onTap:()=>showDialog(context:context,builder:(_)=>GiftDetails(controller:controller,gift:gift)),child:Padding(padding:const EdgeInsets.all(10),child:Column(children:[const Expanded(child:Center(child:SecretPacketGift(size:105))),Text('Секретный пакетик #${gift.serial.toString().padLeft(4,'0')}',textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12)),const Text('Rare',style:TextStyle(color:Color(0xFF7EB6FF),fontSize:11))])))); }
class GiftDetails extends StatelessWidget { const GiftDetails({super.key,required this.controller,required this.gift}); final AppController controller; final GiftInstance gift; @override Widget build(BuildContext context){final sender=controller.userById(gift.senderId);return AlertDialog(title:Text('Секретный пакетик #${gift.serial.toString().padLeft(4,'0')}'),content:Column(mainAxisSize:MainAxisSize.min,children:[const SecretPacketGift(size:150),Text('От: ${sender.name}'),if(gift.note.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text('«${gift.note}»'))]),actions:[TextButton(onPressed:(){controller.toggleGiftPin(gift.id);Navigator.pop(context);},child:Text(gift.pinned?'Открепить':'Закрепить')),TextButton(onPressed:(){controller.hideGift(gift.id);Navigator.pop(context);},child:const Text('Скрыть')),FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Готово'))]);}}

class SecretPacketGift extends StatefulWidget { const SecretPacketGift({super.key,this.size=140}); final double size; @override State<SecretPacketGift> createState()=>_SecretPacketGiftState(); }
class _SecretPacketGiftState extends State<SecretPacketGift> with SingleTickerProviderStateMixin { late final AnimationController c; @override void initState(){super.initState();c=AnimationController(vsync:this,duration:const Duration(milliseconds:2600))..repeat();} @override void dispose(){c.dispose();super.dispose();} @override Widget build(BuildContext context)=>AnimatedBuilder(animation:c,builder:(_,child){final t=c.value*math.pi*2;return Transform.translate(offset:Offset(0,math.sin(t)*4),child:Transform.rotate(angle:math.sin(t*.7)*.025,child:Transform.scale(scale:1+math.sin(t)*.012,child:child)));},child:Image.asset('assets/images/secret_packet.png',width:widget.size,height:widget.size,fit:BoxFit.contain)); }

class QrDialog extends StatelessWidget { const QrDialog({super.key,required this.username}); final String username; @override Widget build(BuildContext context)=>AlertDialog(title:const Text('QR профиля'),content:Column(mainAxisSize:MainAxisSize.min,children:[Container(width:190,height:190,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:const Icon(Icons.qr_code_2_rounded,color:Colors.black,size:160)),const SizedBox(height:10),SelectableText('onespase://user/$username')]),actions:[FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Готово'))]); }

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final AppController controller;

  Widget tile(BuildContext context, IconData icon, String title, String subtitle, Color color, Widget screen) => Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle, style: const TextStyle(color: OneSpaseTheme.secondary)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
        ),
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Настройки', style: TextStyle(fontWeight: FontWeight.w900))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
            children: [
              tile(context, Icons.workspace_premium_rounded, 'OneSpase Plus', controller.isPlus ? 'Plus активен · расширенные возможности' : 'Темы, реакции и повышенные лимиты', const Color(0xFF9D6CFF), OneSpasePlusScreen(controller: controller)),
              tile(context, Icons.switch_account_rounded, 'Аккаунты', '${controller.accounts.length}/${controller.maxAccounts} · добавить и переключаться', const Color(0xFF55A8FF), AccountManagerScreen(controller: controller)),
              tile(context, Icons.palette_rounded, 'Оформление профиля', 'Тема, emoji-status, музыка, канал', OneSpaseTheme.accent, ProfileCustomizationScreen(controller: controller)),
              tile(context, Icons.add_reaction_rounded, 'Emoji Studio', '${controller.emojiPacks.length}/${controller.maxEmojiPacks} emoji-паков', const Color(0xFFFFA726), EmojiStudioScreen(controller: controller)),
              tile(context, Icons.key_rounded, 'Конфиденциальность', 'Онлайн, блокировки, кто может писать', const Color(0xFF47D268), PrivacyScreen(controller: controller)),
              tile(context, Icons.notifications_outlined, 'Уведомления', 'Сообщения, реакции, подарки', const Color(0xFFFF5D73), NotificationSettingsScreen(controller: controller)),
              tile(context, Icons.storage_rounded, 'Данные и память', 'Кэш и загрузка медиа', const Color(0xFF5F82FF), DataSettingsScreen(controller: controller)),
              tile(context, Icons.admin_panel_settings_rounded, 'Owner Panel', 'Галочки и защищённые username', const Color(0xFFFF3B4D), OwnerPanelScreen(controller: controller)),
              const SizedBox(height: 8),
              const Card(child: ListTile(contentPadding: EdgeInsets.all(16), leading: Icon(Icons.science_outlined, color: OneSpaseTheme.accent), title: Text('Offline Prototype v0.7.1', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('Plus работает локально. Реальные платежи пока не подключены.', style: TextStyle(color: OneSpaseTheme.secondary)))),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Сбросить демо?'), content: const Text('Вернутся стандартные пользователи, чаты, посты и подарки.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Сбросить'))]));
                  if (ok == true) { await controller.resetDemo(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Демо-данные восстановлены'))); }
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Сбросить демо-данные'),
              ),
            ],
          ),
        ),
      );
}

class OneSpasePlusScreen extends StatelessWidget {
  const OneSpasePlusScreen({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('OneSpase Plus', style: TextStyle(fontWeight: FontWeight.w900))),
          body: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(colors: [Color(0xFF7048FF), Color(0xFFB35CFF), Color(0xFFFFB84D)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Column(children: [
                  const Icon(Icons.auto_awesome_rounded, size: 54, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text('OneSpase Plus', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(controller.isPlus ? 'Подписка активна на этом локальном аккаунте' : 'Больше кастомизации и удобства — базовые чаты остаются бесплатными', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                ]),
              ),
              const SizedBox(height: 14),
              const _PlusPerk(icon: Icons.switch_account_rounded, title: 'До 5 аккаунтов', subtitle: 'В бесплатной версии — до 2.'),
              const _PlusPerk(icon: Icons.add_reaction_rounded, title: 'Расширенные реакции', subtitle: '🔥 🤯 👑 🚀 ✨ плюс к базовым реакциям.'),
              const _PlusPerk(icon: Icons.palette_rounded, title: 'Эксклюзивные темы', subtitle: 'Aurora, Midnight и Gold.'),
              const _PlusPerk(icon: Icons.emoji_emotions_rounded, title: 'До 20 emoji-паков', subtitle: 'В бесплатной версии — до 3.'),
              const _PlusPerk(icon: Icons.auto_stories_rounded, title: 'До 20 активных Stories', subtitle: 'В бесплатной версии — до 3; Plus-Stories выше в демо-ленте.'),
              const _PlusPerk(icon: Icons.workspace_premium_rounded, title: 'Plus badge и рамка профиля', subtitle: 'Значок возле имени и градиентная рамка аватара.'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async { await controller.setPlus(!controller.isPlus); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.isPlus ? 'OneSpase Plus включён для демо' : 'OneSpase Plus выключен'))); },
                icon: Icon(controller.isPlus ? Icons.close_rounded : Icons.auto_awesome_rounded),
                label: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(controller.isPlus ? 'Отключить демо-Plus' : 'Активировать демо-Plus')),
              ),
              const SizedBox(height: 10),
              const Text('Это offline-прототип. Реальная покупка, цена и Google Play Billing будут подключаться только на серверном этапе.', textAlign: TextAlign.center, style: TextStyle(color: OneSpaseTheme.secondary, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      );
}

class _PlusPerk extends StatelessWidget {
  const _PlusPerk({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0x229D6CFF), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFFB99BFF))), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text(subtitle, style: const TextStyle(color: OneSpaseTheme.secondary))));
}

class AccountManagerScreen extends StatelessWidget { const AccountManagerScreen({super.key,required this.controller}); final AppController controller; @override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(_,__)=>Scaffold(appBar:AppBar(title:const Text('Аккаунты')),floatingActionButton:FloatingActionButton.extended(onPressed:()=>_add(context),icon:const Icon(Icons.person_add_alt_1),label:const Text('Добавить')),body:ListView(padding:const EdgeInsets.all(14),children:controller.accounts.map((a){final u=controller.userById(a.userId);final active=a.id==controller.currentAccountId;return Card(child:ListTile(leading:UserAvatar(user:u),title:Text(u.name,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('@${u.username}${active?' · активный':''}'),trailing:active?const Icon(Icons.check_circle,color:OneSpaseTheme.accent):PopupMenuButton<String>(onSelected:(v){if(v=='switch')controller.switchAccount(a.id);if(v=='delete')controller.removeAccount(a.id);},itemBuilder:(_)=>const[PopupMenuItem(value:'switch',child:Text('Переключиться')),PopupMenuItem(value:'delete',child:Text('Удалить'))]),onTap:()=>controller.switchAccount(a.id)));}).toList()))); Future<void> _add(BuildContext context)async{final n=TextEditingController(),u=TextEditingController();String?err;await showDialog(context:context,builder:(_)=>StatefulBuilder(builder:(context,set)=>AlertDialog(title:const Text('Новый локальный аккаунт'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Имя')),const SizedBox(height:8),TextField(controller:u,decoration:const InputDecoration(labelText:'Username',prefixText:'@')),if(err!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text(err!,style:const TextStyle(color:Colors.redAccent)))]),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Отмена')),FilledButton(onPressed:()async{final e=await controller.addAccount(n.text,u.text);if(e!=null){set(()=>err=e);}else if(context.mounted)Navigator.pop(context);},child:const Text('Создать'))])));n.dispose();u.dispose();}}

class ProfileCustomizationScreen extends StatefulWidget {
  const ProfileCustomizationScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<ProfileCustomizationScreen> createState() => _ProfileCustomizationScreenState();
}

class _ProfileCustomizationScreenState extends State<ProfileCustomizationScreen> {
  late String theme;
  late final TextEditingController emoji, music, channel;
  @override
  void initState() { super.initState(); final m = widget.controller.me; theme = m.theme; emoji = TextEditingController(text: m.emojiStatus); music = TextEditingController(text: m.music); channel = TextEditingController(text: m.channel); }
  @override
  void dispose() { emoji.dispose(); music.dispose(); channel.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const freeThemes = ['purple','blue','sunset','mint'];
    const plusThemes = ['aurora','midnight','gold'];
    final allThemes = [...freeThemes, ...plusThemes];
    return Scaffold(
      appBar: AppBar(title: const Text('Оформление профиля')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          const Text('Тема профиля', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: allThemes.map((t) {
            final locked = plusThemes.contains(t) && !widget.controller.isPlus;
            return ChoiceChip(
              avatar: locked ? const Icon(Icons.lock_rounded, size: 15) : plusThemes.contains(t) ? const Icon(Icons.auto_awesome_rounded, size: 15) : null,
              label: Text(t),
              selected: theme == t,
              onSelected: (_) { if (locked) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Эта тема доступна в OneSpase Plus'))); return; } setState(() => theme = t); },
            );
          }).toList()),
          const SizedBox(height: 16),
          TextField(controller: emoji, maxLength: 8, decoration: const InputDecoration(labelText: 'Emoji-status', hintText: '🎧')),
          const SizedBox(height: 8),
          TextField(controller: music, decoration: const InputDecoration(labelText: 'Музыка профиля')),
          const SizedBox(height: 8),
          TextField(controller: channel, decoration: const InputDecoration(labelText: 'Закреплённый канал', prefixText: '@')),
          const SizedBox(height: 14),
          FilledButton(onPressed: () async { await widget.controller.customize(theme: theme, emoji: emoji.text, music: music.text, channel: channel.text); if (context.mounted) Navigator.pop(context); }, child: const Text('Сохранить')),
        ],
      ),
    );
  }
}

class EmojiStudioScreen extends StatelessWidget {
  const EmojiStudioScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: Text('Emoji Studio · ${controller.emojiPacks.length}/${controller.maxEmojiPacks}')),
          floatingActionButton: FloatingActionButton.extended(onPressed: () => _create(context), icon: const Icon(Icons.add_reaction), label: const Text('Создать')),
          body: ListView(padding: const EdgeInsets.all(14), children: controller.emojiPacks.map((p) => Card(child: ListTile(title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w900)), subtitle: Text('${p.items.join('  ')}\n/${p.slug}'), isThreeLine: true, trailing: IconButton(onPressed: () => controller.deleteEmojiPack(p.id), icon: const Icon(Icons.delete_outline))))).toList()),
        ),
      );

  Future<void> _create(BuildContext context) async {
    final t = TextEditingController(), s = TextEditingController(), e = TextEditingController(text: '🐱 💜 🚀');
    String? error;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setState) => AlertDialog(
        title: const Text('Новый emoji-пак'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: t, decoration: const InputDecoration(labelText: 'Название')),
          const SizedBox(height: 8),
          TextField(controller: s, decoration: const InputDecoration(labelText: 'Slug')),
          const SizedBox(height: 8),
          TextField(controller: e, decoration: const InputDecoration(labelText: 'Emoji через пробел')),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: const TextStyle(color: Colors.redAccent))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () async { final err = await controller.createEmojiPack(t.text, s.text, e.text.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList()); if (err != null) { setState(() => error = err); } else if (context.mounted) { Navigator.pop(context); } }, child: const Text('Создать')),
        ],
      )),
    );
    t.dispose(); s.dispose(); e.dispose();
  }
}

class PrivacyScreen extends StatelessWidget { const PrivacyScreen({super.key,required this.controller});final AppController controller;Widget drop(String title,String value,ValueChanged<String?> onChanged)=>Card(child:Padding(padding:const EdgeInsets.symmetric(horizontal:14,vertical:6),child:DropdownButtonFormField<String>(value:value,decoration:InputDecoration(labelText:title,fillColor:Colors.transparent),items:['Все','Друзья','Никто'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:onChanged)));@override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(_,__)=>Scaffold(appBar:AppBar(title:const Text('Конфиденциальность')),body:ListView(padding:const EdgeInsets.all(14),children:[drop('Кто видит онлайн',controller.settings.onlineVisibility,(v){if(v!=null){controller.settings.onlineVisibility=v;controller.updateSettings();}}),drop('Последняя активность',controller.settings.lastSeenVisibility,(v){if(v!=null){controller.settings.lastSeenVisibility=v;controller.updateSettings();}}),drop('Кто может писать',controller.settings.messagePermission,(v){if(v!=null){controller.settings.messagePermission=v;controller.updateSettings();}}),drop('Кто может звонить',controller.settings.callPermission,(v){if(v!=null){controller.settings.callPermission=v;controller.updateSettings();}}),const SizedBox(height:10),const Text('Заблокированные',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900)),...controller.users.where((u)=>u.id!=controller.me.id).map((u)=>SwitchListTile(title:Text(u.name),subtitle:Text('@${u.username}'),value:u.blocked,onChanged:(_)=>controller.block(u.id))) ])));}

class NotificationSettingsScreen extends StatelessWidget { const NotificationSettingsScreen({super.key,required this.controller});final AppController controller;@override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(_,__)=>Scaffold(appBar:AppBar(title:const Text('Уведомления')),body:ListView(padding:const EdgeInsets.all(14),children:[sw('Личные сообщения',controller.settings.notifMessages,(v)=>controller.settings.notifMessages=v),sw('Реакции',controller.settings.notifReactions,(v)=>controller.settings.notifReactions=v),sw('Подарки',controller.settings.notifGifts,(v)=>controller.settings.notifGifts=v),sw('Сообщества',controller.settings.notifCommunities,(v)=>controller.settings.notifCommunities=v),sw('Звук',controller.settings.notifSound,(v)=>controller.settings.notifSound=v),sw('Вибрация',controller.settings.notifVibration,(v)=>controller.settings.notifVibration=v),sw('Предпросмотр текста',controller.settings.previewText,(v)=>controller.settings.previewText=v)])));Widget sw(String title,bool value,ValueChanged<bool> set)=>Card(child:SwitchListTile(title:Text(title),value:value,onChanged:(v){set(v);controller.updateSettings();}));}

class DataSettingsScreen extends StatelessWidget { const DataSettingsScreen({super.key,required this.controller});final AppController controller;@override Widget build(BuildContext context)=>AnimatedBuilder(animation:controller,builder:(_,__)=>Scaffold(appBar:AppBar(title:const Text('Данные и память')),body:ListView(padding:const EdgeInsets.all(14),children:[Card(child:ListTile(leading:const Icon(Icons.storage_rounded),title:const Text('Локальные данные'),subtitle:Text('≈ ${(controller.cacheBytes/1024).toStringAsFixed(1)} КБ'))),Card(child:SwitchListTile(title:const Text('Автозагрузка фото'),value:controller.settings.autoPhoto,onChanged:(v){controller.settings.autoPhoto=v;controller.updateSettings();})),Card(child:SwitchListTile(title:const Text('Автозагрузка видео'),value:controller.settings.autoVideo,onChanged:(v){controller.settings.autoVideo=v;controller.updateSettings();})),Card(child:SwitchListTile(title:const Text('Автозагрузка файлов'),value:controller.settings.autoFiles,onChanged:(v){controller.settings.autoFiles=v;controller.updateSettings();})),Card(child:SwitchListTile(title:const Text('Экономия трафика'),value:controller.settings.dataSaver,onChanged:(v){controller.settings.dataSaver=v;controller.updateSettings();})),const SizedBox(height:10),OutlinedButton.icon(onPressed:()async{await controller.clearChatCache();if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Локальные сообщения очищены')));},icon:const Icon(Icons.cleaning_services_outlined),label:const Text('Очистить демо-сообщения'))])));}

class OwnerPanelScreen extends StatefulWidget { const OwnerPanelScreen({super.key,required this.controller});final AppController controller;@override State<OwnerPanelScreen> createState()=>_OwnerPanelScreenState();}
class _OwnerPanelScreenState extends State<OwnerPanelScreen> {
  final reserve = TextEditingController();

  @override
  void dispose() {
    reserve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.controller,
        builder: (_, __) => Scaffold(
          appBar: AppBar(title: const Text('Owner Panel')),
          body: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Text('Верификация', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ...widget.controller.users.map(
                (u) => Card(
                  child: ListTile(
                    leading: UserAvatar(user: u),
                    title: Text(u.name),
                    subtitle: Text('@${u.username} · ${u.verification}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => widget.controller.setVerification(u.id, v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'none', child: Text('Без галочки')),
                        PopupMenuItem(value: 'blue', child: Text('🔵 Verified')),
                        PopupMenuItem(value: 'red', child: Text('🔴 Official')),
                        PopupMenuItem(value: 'purple', child: Text('🟣 Creator')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Зарезервировать username', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: reserve, decoration: const InputDecoration(prefixText: '@', hintText: 'username'))),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () async {
                      await widget.controller.reserveUsername(reserve.text);
                      reserve.clear();
                    },
                    icon: const Icon(Icons.lock_outline),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.controller.reservedUsernames.map((e) => Chip(label: Text('@$e'))).toList(),
              ),
            ],
          ),
        ),
      );
}
