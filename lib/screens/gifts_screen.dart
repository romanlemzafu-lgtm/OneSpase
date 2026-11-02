import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models/gift_item.dart';
import '../theme/onespase_theme.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refreshExtras();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подарки', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final gifts = widget.controller.gifts;
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 30),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded, color: OneSpaseTheme.accent, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Коллекция профиля', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('${gifts.length} подарков', style: const TextStyle(color: OneSpaseTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (gifts.isEmpty)
                const _EmptyGifts()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gifts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.93,
                  ),
                  itemBuilder: (context, index) => _GiftCard(gift: gifts[index]),
                ),
              const SizedBox(height: 18),
              const Text(
                'В v0.6 подарки бесплатные и без торговли за реальные деньги. Редкость и серийный номер задаются сервером.',
                style: TextStyle(color: OneSpaseTheme.textSecondary, fontSize: 12, height: 1.35),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard({required this.gift});
  final GiftItem gift;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(gift.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 10),
            Text(gift.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(
              gift.serialNumber == null ? gift.rarity.toUpperCase() : '${gift.rarity.toUpperCase()}  #${gift.serialNumber}',
              style: const TextStyle(color: OneSpaseTheme.accent, fontSize: 11, fontWeight: FontWeight.w800),
            ),
            if ((gift.senderName ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('от ${gift.senderName}', style: const TextStyle(color: OneSpaseTheme.textSecondary, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyGifts extends StatelessWidget {
  const _EmptyGifts();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: const [
            Text('🎁', style: TextStyle(fontSize: 52)),
            SizedBox(height: 10),
            Text('Пока пусто', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            SizedBox(height: 4),
            Text('Когда тебе отправят подарок, он появится здесь.', textAlign: TextAlign.center, style: TextStyle(color: OneSpaseTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
