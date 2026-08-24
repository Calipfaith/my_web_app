import 'package:flutter/material.dart';

import '../services/queen_service.dart';

const _dashboardYellow = Color(0xFFFFC107);
const _dashboardOrange = Color(0xFFFF8A00);
const _dashboardBrown = Color(0xFF54240E);

class QueenDashboardPage extends StatefulWidget {
  const QueenDashboardPage({super.key});

  @override
  State<QueenDashboardPage> createState() => _QueenDashboardPageState();
}

class _QueenDashboardPageState extends State<QueenDashboardPage> {
  final service = QueenService();
  bool liveDrop = false;
  int nectarPoints = 1250;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF4D8),
    appBar: AppBar(
      backgroundColor: _dashboardYellow,
      foregroundColor: _dashboardBrown,
      title: Row(
        children: [
          Image.asset(
            'assets/queen.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bee Dashboard',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '$nectarPoints Nectar Points',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Image.asset('assets/honey_pot.png', width: 38, height: 38),
        ],
      ),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: service.fetchAnalytics(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _identityBanner(),
            const SizedBox(height: 16),
            _sectionRow(context, 'Live Drops', Icons.live_tv, [
              _dropPanel(context, data),
              _honeycombPanel(),
            ]),
            const SizedBox(height: 16),
            _sectionRow(context, 'Hive Connections', Icons.hive, [
              _connectionsPanel(),
              _earningsPanel(data),
            ]),
            const SizedBox(height: 16),
            _analyticsPanel(data),
          ],
        );
      },
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 1,
      selectedItemColor: _dashboardOrange,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Storefront'),
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Messages'),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard),
          label: 'Rewards',
        ),
      ],
      onTap: (index) {
        if (index == 0) Navigator.pushNamed(context, '/queen');
      },
    ),
  );

  Widget _identityBanner() => Card(
    color: _dashboardBrown,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: _dashboardYellow,
            child: Image.asset('assets/queen.png', width: 56, height: 56),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BuzzBee',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Hive: Fashion Frenzy',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          const Icon(Icons.people, color: _dashboardYellow, size: 32),
          const SizedBox(width: 8),
          const Text(
            'Active hive',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _sectionRow(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(
          children: [
            Icon(icon, color: _dashboardOrange),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: _dashboardBrown,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700)
            return Column(
              children: [
                for (final child in children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: child,
                  ),
              ],
            );
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 12),
              Expanded(child: children[1]),
            ],
          );
        },
      ),
    ],
  );

  Widget _dropPanel(BuildContext context, Map<String, dynamic> data) =>
      _panel('Upcoming Live Drops', Icons.schedule, [
        _actionButton('Schedule Drop', Icons.add, _createEvent),
        _infoTile('Fashion Haul', '7:00 PM', Icons.checkroom),
        _infoTile('Beauty Deals', 'Tomorrow • 5:00 PM', Icons.spa),
        TextButton(onPressed: () {}, child: const Text('View Past Streams')),
      ]);

  Widget _honeycombPanel() => _panel('My Honeycombs', Icons.grid_view, [
    Row(
      children: [
        Expanded(
          child: _honeycombProduct(
            'Chic Dress',
            'assets/product1.png',
            '5.2k Views',
          ),
        ),
        Expanded(
          child: _honeycombProduct(
            'Smartwatch',
            'assets/product2.png',
            '220 Likes',
          ),
        ),
        Expanded(
          child: _honeycombProduct(
            'Glam Lipstick',
            'assets/placeholder_beauty.png',
            '180 Likes',
          ),
        ),
      ],
    ),
    _actionButton('Add New Product', Icons.add, () {}),
  ]);

  Widget _connectionsPanel() => _panel('Hive Connections', Icons.hive, [
    _infoTile(
      'Invite from Queen Bee “Fashion Frenzy”',
      'Pending',
      Icons.favorite,
    ),
    _infoTile('Co-Host Request from BellaBee', 'Pending', Icons.handshake),
    _infoTile('Joined Hives', 'Fashion Frenzy • Glam Home', Icons.home),
    _actionButton('Manage Hives', Icons.arrow_forward, () {}),
  ]);

  Widget _earningsPanel(Map<String, dynamic> data) =>
      _panel('Earnings & Rewards', Icons.paid, [
        _valueTile('Today’s Sales', 'RM${data['gmv'] ?? 350}', Icons.payments),
        _valueTile(
          'Nectar Earned',
          '+${data['nectarIssued'] ?? 300}',
          Icons.stars,
        ),
        _valueTile(
          'Honey Pot Entries',
          '${data['honeyPotEntries'] ?? 2}',
          Icons.savings,
        ),
        Row(
          children: [
            Image.asset('assets/honey_pot.png', width: 76, height: 76),
            const Spacer(),
            Image.asset('assets/honey_pot.png', width: 76, height: 76),
          ],
        ),
      ]);

  Widget _analyticsPanel(Map<String, dynamic> data) =>
      _panel('Analytics Overview', Icons.insights, [
        Row(
          children: [
            Expanded(
              child: _valueTile(
                'Viewers',
                '${data['viewers'] ?? '1.2k'}',
                Icons.visibility,
              ),
            ),
            Expanded(
              child: _valueTile(
                'Total Sales',
                'RM${data['gmv'] ?? '8,750'}',
                Icons.paid,
              ),
            ),
            Expanded(
              child: _valueTile(
                'Nectar Points',
                '+${data['nectarIssued'] ?? '4,200'}',
                Icons.stars,
              ),
            ),
            Expanded(
              child: _valueTile(
                'Tips Received',
                'RM${data['tips'] ?? '180'}',
                Icons.savings,
              ),
            ),
          ],
        ),
      ]);

  Widget _panel(String title, IconData icon, List<Widget> children) => Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _dashboardOrange),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _dashboardBrown,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Divider(),
          ...children,
        ],
      ),
    ),
  );

  Widget _actionButton(String label, IconData icon, VoidCallback action) =>
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: action,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: _dashboardOrange,
            foregroundColor: Colors.white,
          ),
        ),
      );

  Widget _infoTile(String title, String subtitle, IconData icon) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: _dashboardOrange),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
  );

  Widget _valueTile(String label, String value, IconData icon) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: _dashboardOrange),
    title: Text(label),
    trailing: Text(
      value,
      style: const TextStyle(
        color: _dashboardBrown,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _honeycombProduct(String title, String image, String stat) => Padding(
    padding: const EdgeInsets.all(4),
    child: Column(
      children: [
        Image.asset(image, height: 72, fit: BoxFit.contain),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        Text(stat, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );

  Future<void> _createEvent() async {
    final title = TextEditingController();
    final date = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Drop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Drop title'),
            ),
            TextField(
              controller: date,
              decoration: const InputDecoration(labelText: 'Date and time'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != true || title.text.trim().isEmpty || date.text.trim().isEmpty)
      return;
    try {
      await service.createEvent(
        title: title.text.trim(),
        date: date.text.trim(),
        reward: '10 Nectar',
      );
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Drop scheduled.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to schedule drop.')),
        );
    }
  }
}
