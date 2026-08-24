import 'package:flutter/material.dart';

import '../services/queen_service.dart';

const _yellow = Color(0xFFFFC107);
const _orange = Color(0xFFFF8A00);
const _ink = Color(0xFF4A2416);

class QueenStorefrontPage extends StatefulWidget {
  const QueenStorefrontPage({super.key});

  @override
  State<QueenStorefrontPage> createState() => _QueenStorefrontPageState();
}

class _QueenStorefrontPageState extends State<QueenStorefrontPage> {
  final service = QueenService();
  final chatController = TextEditingController();
  bool followingDrop = false;
  int selectedNav = 0;

  @override
  void dispose() {
    chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: _header(),
      body: FutureBuilder<List<dynamic>>(
        future: service.fetchDrops(),
        builder: (context, snapshot) {
          final drops = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              _sectionTitle('Featured Drops'),
              _drops(drops),
              const SizedBox(height: 24),
              _sectionTitle('Upcoming Events'),
              _events(),
              const SizedBox(height: 22),
              _rewards(),
              const SizedBox(height: 22),
              _sectionTitle('Hive Chat'),
              _chat(),
            ],
          );
        },
      ),
      bottomNavigationBar: _bottomNavigation(),
    );
  }

  PreferredSizeWidget _header() => AppBar(
    backgroundColor: _yellow,
    foregroundColor: Colors.black,
    elevation: 2,
    titleSpacing: 12,
    title: Row(
      children: [
        Image.asset('assets/frenzybees_logo.png', width: 42, height: 42),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Welcome, Queen Bee Olivia!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Image.asset(
            'assets/queen.png',
            width: 38,
            height: 38,
            fit: BoxFit.contain,
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontSize: 24,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _drops(List<dynamic> drops) {
    final items = drops.isEmpty
        ? const [
            {
              'name': 'New Glam Collection',
              'image': 'assets/placeholder_beauty.png',
              'description': 'Fresh beauty picks',
              'nectar': 50,
              'price': 120,
            },
            {
              'name': 'Tech Deals',
              'image': 'assets/product2.png',
              'description': 'Smart hive essentials',
              'nectar': 80,
              'price': 999,
            },
            {
              'name': 'Summer Sale',
              'image': 'assets/placeholder_home.png',
              'description': 'Seasonal favourites',
              'nectar': 30,
              'price': 89,
            },
          ]
        : drops;
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 10),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final drop = items[index] as Map<String, dynamic>;
          return SizedBox(
            width: 230,
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 2,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      '${drop['image'] ?? 'assets/placeholder_fashion.png'}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/placeholder_fashion.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: .28),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${drop['name'] ?? 'Featured Drop'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 6),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(112, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Text('Shop Now'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _events() => FutureBuilder<List<dynamic>>(
    future: service.fetchEvents(),
    builder: (context, snapshot) {
      final events = snapshot.data ?? const [];
      final first = events.isNotEmpty
          ? events.first as Map<String, dynamic>
          : const <String, dynamic>{};
      return Row(
        children: [
          Expanded(
            child: _eventCard(
              '${first['title'] ?? 'Hive Party Live Stream'}',
              '${first['date'] ?? 'June 18, 7:00 PM'}',
              'assets/hero_bee.png',
              'Join Event',
              true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _eventCard(
              'Buzzing Yoga Session',
              'June 22, 10:00 AM',
              'assets/queen.png',
              'View Details',
              false,
            ),
          ),
        ],
      );
    },
  );

  Widget _eventCard(
    String title,
    String date,
    String image,
    String action,
    bool primary,
  ) => Card(
    clipBehavior: Clip.antiAlias,
    elevation: 2,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 92, child: Image.asset(image, fit: BoxFit.cover)),
        Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
                maxLines: 2,
              ),
              Text(
                date,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: primary
                        ? _orange
                        : const Color(0xFF174B9B),
                    minimumSize: const Size.fromHeight(32),
                  ),
                  child: Text(action),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _rewards() => Card(
    elevation: 2,
    color: const Color(0xFFFFE8A8),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: Column(
        children: [
          Image.asset('assets/honey_pot.png', height: 68),
          const Text(
            'Honey Pot Rewards!',
            style: TextStyle(
              color: _ink,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _RewardStat('1,250', 'Nectar Points'),
              _RewardStat('5', 'Reward Offers'),
              _RewardStat('10', 'Redeemed Gifts'),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              minimumSize: const Size(210, 40),
            ),
            child: const Text('View Rewards'),
          ),
        ],
      ),
    ),
  );

  Widget _chat() => Column(
    children: [
      _messageTile('Queen Clara', 'Excited for the new collection launch!'),
      _messageTile('Beekeeper Dan', "Can't wait to join the Hive Party!"),
      const SizedBox(height: 8),
      TextField(
        controller: chatController,
        decoration: InputDecoration(
          hintText: 'Ask the Queen or share your thoughts...',
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    ],
  );

  Widget _messageTile(String user, String message) => Card(
    child: ListTile(
      leading: CircleAvatar(backgroundColor: _yellow, child: Text(user[0])),
      title: Text(user, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(message),
    ),
  );

  Future<void> _sendMessage() async {
    final message = chatController.text.trim();
    if (message.isEmpty) return;
    try {
      await service.postChat('next-drop', message);
      chatController.clear();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent to the hive.')),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to join Hive Chat.')),
        );
    }
  }

  Widget _bottomNavigation() => BottomNavigationBar(
    currentIndex: selectedNav,
    selectedItemColor: _orange,
    type: BottomNavigationBarType.fixed,
    onTap: (index) {
      setState(() => selectedNav = index);
      if (index == 1) Navigator.pushNamed(context, '/queen/dashboard');
      if (index == 3) Navigator.pushNamed(context, '/profile');
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
      BottomNavigationBarItem(
        icon: Icon(Icons.card_giftcard),
        label: 'Rewards',
      ),
    ],
  );
}

class _RewardStat extends StatelessWidget {
  final String value;
  final String label;
  const _RewardStat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: _ink,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(label, style: const TextStyle(color: _ink, fontSize: 11)),
    ],
  );
}
