import 'package:flutter/material.dart';

import '../services/bee_service.dart';

class BeeDashboardPage extends StatefulWidget {
  const BeeDashboardPage({super.key});

  @override
  State<BeeDashboardPage> createState() => _BeeDashboardPageState();
}

class _BeeDashboardPageState extends State<BeeDashboardPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bee Dashboard')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: BeeService().fetchDashboard(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Your hive activity',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _section('Live Drops', Icons.live_tv, [
              _value(
                'Upcoming drop',
                '${data['nextDrop'] ?? 'No drop scheduled'}',
              ),
              _action(context, 'View Queen Storefront', Icons.store, '/queen'),
              _action(
                context,
                'Start a Live Drop',
                Icons.add_circle_outline,
                '/bee',
                action: _startLiveDrop,
              ),
            ]),
            _section('My Honeycombs', Icons.grid_view, [
              _value('Published honeycombs', '${data['honeycombs'] ?? 0}'),
              _value('Views', '${data['views'] ?? 0}'),
              _action(context, 'Add New Product', Icons.add, '/productGrid'),
            ]),
            _section('Hive Connections', Icons.hive, [
              _value('Joined hives', '${data['joinedHives'] ?? 0}'),
              _value('Co-host requests', '${data['coHostRequests'] ?? 0}'),
              _action(
                context,
                'Manage Hives',
                Icons.arrow_forward,
                '/queen',
                action: _inviteCoHost,
              ),
              _action(
                context,
                'Review Co-host Requests',
                Icons.handshake,
                '/bee',
                action: _reviewCoHosts,
              ),
            ]),
            _section('Earnings & Rewards', Icons.stars, [
              _value("Today's sales", 'RM${data['sales'] ?? 0}'),
              _value('Nectar earned', '+${data['nectar'] ?? 0}'),
              _value('Honey Pot entries', '${data['honeyPotEntries'] ?? 0}'),
            ]),
            _section('Analytics Overview', Icons.insights, [
              _value('Viewers', '${data['viewers'] ?? 0}'),
              _value('Total sales', 'RM${data['totalSales'] ?? 0}'),
              _value('Tips received', 'RM${data['tips'] ?? 0}'),
            ]),
          ],
        );
      },
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 1,
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

  Widget _section(String title, IconData icon, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
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

  Widget _value(String label, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
  );

  Widget _action(
    BuildContext context,
    String label,
    IconData icon,
    String route, {
    VoidCallback? action,
  }) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right),
    onTap: action ?? () => Navigator.pushNamed(context, route),
  );

  Future<void> _startLiveDrop() async {
    final title = TextEditingController();
    final date = TextEditingController();
    final product = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a Live Drop'),
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
            TextField(
              controller: product,
              decoration: const InputDecoration(labelText: 'Featured product'),
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
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
    if (saved != true ||
        title.text.trim().isEmpty ||
        date.text.trim().isEmpty ||
        product.text.trim().isEmpty)
      return;
    try {
      final drop = await BeeService().createDrop(
        title: title.text.trim(),
        date: date.text.trim(),
        product: product.text.trim(),
      );
      if (mounted) {
        Navigator.pushNamed(context, '/live', arguments: drop['dropId']);
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to schedule live drop.')),
        );
    }
  }

  Future<void> _inviteCoHost() async {
    final username = TextEditingController();
    final invited = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Co-host'),
        content: TextField(
          controller: username,
          decoration: const InputDecoration(labelText: 'Bee or Queen username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send invite'),
          ),
        ],
      ),
    );
    if (invited != true || username.text.trim().isEmpty) return;
    try {
      await BeeService().inviteCoHost(username.text.trim());
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Co-host invitation sent.')),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to send invitation.')),
        );
    }
  }

  Future<void> _reviewCoHosts() async {
    try {
      final requests = await BeeService().fetchCollaborations();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Co-host Requests'),
          content: requests.isEmpty
              ? const Text('No co-host requests yet.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final request in requests)
                      ListTile(
                        title: Text('${request['invitee'] ?? 'Hive member'}'),
                        subtitle: Text('${request['status'] ?? 'pending'}'),
                        trailing: request['status'] == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () async {
                                      await BeeService().decideCollaboration(
                                        collaborationId:
                                            request['collaborationId'],
                                        decision: 'accepted',
                                      );
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () async {
                                      await BeeService().decideCollaboration(
                                        collaborationId:
                                            request['collaborationId'],
                                        decision: 'rejected',
                                      );
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    },
                                  ),
                                ],
                              )
                            : null,
                      ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to load co-host requests.')),
        );
    }
  }
}
