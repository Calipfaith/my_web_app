import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_store.dart';

const Color frenzyYellow = Color(0xFFFFC107);
const Color frenzyOrange = Color(0xFFFF8A00);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String name;
  late final String email;
  String phone = '';
  String address = '';
  String payment = '';
  bool notificationsEnabled = true;
  bool subscriptionEnabled = false;
  List<dynamic> wishlist = [];
  List<dynamic> linkedAccounts = [];
  int rewardPoints = 320;

  @override
  void initState() {
    super.initState();
    name = AuthService.displayName ?? 'Bee member';
    email = AuthService.email ?? 'member@frenzybees.com';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    Map<String, dynamic> values;
    try {
      values = await ProfileStore().loadRemote();
    } catch (_) {
      values = (await ProfileStore.load()).map(
        (key, value) => MapEntry(key, value),
      );
    }
    final notifications = values['notifications'] is Map
        ? (values['notifications']['email'] as bool? ?? true)
        : await ProfileStore.notificationsEnabled();
    if (!mounted) return;
    setState(() {
      if ((values['name'] as String? ?? '').isNotEmpty)
        name = values['name'] as String;
      phone = values['phone'] as String? ?? '';
      address = values['address'] as String? ?? '';
      payment = values['payment'] as String? ?? '';
      wishlist = values['wishlist'] as List<dynamic>? ?? [];
      linkedAccounts = values['linkedAccounts'] as List<dynamic>? ?? [];
      rewardPoints =
          ((values['rewards'] as Map?)?['points'] as num?)?.toInt() ?? 320;
      subscriptionEnabled =
          (values['subscriptions'] as List<dynamic>?)?.isNotEmpty ?? false;
      notificationsEnabled = notifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: frenzyYellow,
        foregroundColor: Colors.black,
        title: Row(
          children: [
            Image.asset('assets/frenzybees_logo.png', width: 42, height: 42),
            const SizedBox(width: 10),
            const Text(
              'frenzybees',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            for (final label in ['Home', 'Shop', 'Deals', 'Contact'])
              TextButton(
                onPressed: () {},
                child: Text(label, style: const TextStyle(color: Colors.black)),
              ),
            const SizedBox(width: 20),
            SizedBox(
              width: 230,
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Made with AI',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.favorite)),
            Stack(
              children: [
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, '/cart'),
                  icon: const Icon(Icons.shopping_cart),
                ),
                const Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '2',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.person)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 70,
                  backgroundColor: frenzyYellow,
                  child: CircleAvatar(
                    radius: 62,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      'assets/queen.png',
                      width: 92,
                      height: 92,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(email),
                    const Text('Member since 2021'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: frenzyOrange,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _summaryBox(Icons.shopping_bag, 'Orders', '12'),
                _summaryBox(Icons.favorite, 'Wishlist', '8'),
                _summaryBox(Icons.star, 'Frenzy Points', '320'),
                _summaryBox(Icons.card_giftcard, 'Records', '2'),
              ],
            ),
            const SizedBox(height: 16),
            DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: frenzyYellow,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'My Orders'),
                      Tab(text: 'Wishlist'),
                      Tab(text: 'Rewards'),
                      Tab(text: 'Account Settings'),
                      Tab(text: 'Support Tickets'),
                    ],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _ordersWithSidebar(context),
                        _wishlistTab(),
                        _rewardsTab(),
                        _settingsTab(),
                        _supportTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wishlistTab() => Center(
    child: Text(
      wishlist.isEmpty
          ? 'Your wishlist is empty. Save products while shopping.'
          : '${wishlist.length} saved products',
    ),
  );

  Widget _rewardsTab() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$rewardPoints Frenzy Points',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _redeemReward,
          child: const Text('Redeem Rewards'),
        ),
      ],
    ),
  );

  Widget _settingsTab() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Account settings'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _editProfile,
          child: const Text('Edit personal information'),
        ),
        OutlinedButton(
          onPressed: _toggleNotifications,
          child: Text(
            notificationsEnabled
                ? 'Disable notifications'
                : 'Enable notifications',
          ),
        ),
        OutlinedButton(
          onPressed: _toggleSubscription,
          child: Text(
            subscriptionEnabled ? 'Cancel subscription' : 'Start subscription',
          ),
        ),
        OutlinedButton(
          onPressed: () => _updateRemote({
            'linkedAccounts': linkedAccounts,
          }, 'Linked accounts saved.'),
          child: const Text('Save linked accounts'),
        ),
      ],
    ),
  );

  Widget _supportTab() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Need help with your account or order?'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _message('Support request started.'),
          child: const Text('Contact support'),
        ),
      ],
    ),
  );

  void _message(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _updateRemote(
    Map<String, dynamic> values,
    String message,
  ) async {
    try {
      await ProfileStore().updateRemote(values);
      _message(message);
    } catch (_) {
      _message('Unable to save profile changes.');
    }
  }

  Future<void> _toggleSubscription() async {
    final next = !subscriptionEnabled;
    await _updateRemote({
      'subscriptions': next
          ? [
              {'plan': 'FrenzyBees Plus', 'autoRenew': true},
            ]
          : [],
    }, next ? 'Subscription started.' : 'Subscription cancelled.');
    if (mounted) setState(() => subscriptionEnabled = next);
  }

  Future<void> _redeemReward() async {
    try {
      final profile = await ProfileStore().redeemReward();
      final rewards = profile['rewards'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(
        () => rewardPoints =
            (rewards?['points'] as num?)?.toInt() ?? rewardPoints,
      );
      _message('Reward redeemed.');
    } catch (_) {
      _message('Unable to redeem reward.');
    }
  }

  Future<void> _toggleNotifications() async {
    final next = !notificationsEnabled;
    try {
      await ProfileStore().updateRemote({
        'notifications': {'email': next, 'sms': next, 'delivery': next},
      });
    } catch (_) {
      await ProfileStore.setNotificationsEnabled(next);
    }
    if (!mounted) return;
    setState(() => notificationsEnabled = next);
    _message(next ? 'Notifications enabled.' : 'Notifications disabled.');
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);
    final paymentController = TextEditingController(text: payment);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone number'),
              ),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Shipping address',
                ),
              ),
              TextField(
                controller: paymentController,
                decoration: const InputDecoration(labelText: 'Payment method'),
              ),
            ],
          ),
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
    if (saved != true) return;
    try {
      await ProfileStore().updateRemote({
        'name': nameController.text,
        'phone': phoneController.text,
        'address': addressController.text,
        'payment': paymentController.text,
      });
    } catch (_) {
      await ProfileStore.save(
        name: nameController.text,
        phone: phoneController.text,
        address: addressController.text,
        payment: paymentController.text,
      );
    }
    if (!mounted) return;
    setState(() {
      name = nameController.text.trim().isEmpty
          ? name
          : nameController.text.trim();
      phone = phoneController.text.trim();
      address = addressController.text.trim();
      payment = paymentController.text.trim();
    });
    _message('Profile saved.');
  }

  Widget _summaryBox(IconData icon, String label, String value) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: frenzyYellow),
            Text(label),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _ordersList(BuildContext context) => ListView(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _orderCard(context, '10245', 'Mar 15, 2024', 'Shipped', '\$135.00', [
        'assets/product1.png',
        'assets/product2.png',
      ], 'Track Order'),
      _orderCard(context, '10198', 'Feb 28, 2024', 'Delivered', '\$299.00', [
        'assets/product2.png',
      ], 'View Details'),
      _orderCard(context, '10087', 'Feb 12, 2024', 'Cancelled', '\$89.00', [
        'assets/product1.png',
      ], 'Reorder'),
    ],
  );

  Widget _ordersWithSidebar(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final sidebar = Column(
        children: [_rewardsCard(), const SizedBox(height: 16), _accountCard()],
      );
      if (constraints.maxWidth < 760) {
        return ListView(children: [_ordersList(context), sidebar]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _ordersList(context)),
          const SizedBox(width: 24),
          SizedBox(width: 280, child: sidebar),
        ],
      );
    },
  );

  Widget _orderCard(
    BuildContext context,
    String id,
    String date,
    String status,
    String total,
    List<String> images,
    String action,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$id',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Placed on $date',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final image in images)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Image.asset(
                    image,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${images.length} Items',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Total: $total',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Chip(label: Text(status)),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/orders'),
                child: Text(action),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _rewardsCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: frenzyYellow),
              const SizedBox(width: 8),
              const Text(
                'Reward Points',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const Divider(),
          const Text(
            'You have: 320 Points',
            style: TextStyle(
              fontSize: 16,
              color: frenzyYellow,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _redeemReward,
              child: const Text('Redeem Rewards'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _message('More rewards will be available soon.'),
              child: const Text('Earn More Points'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _accountCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: frenzyYellow),
              const SizedBox(width: 8),
              const Text(
                'Account Info',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Shipping Address',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: _editProfile, child: const Text('Edit')),
            ],
          ),
          Text(address.isEmpty ? 'No shipping address saved' : address),
          const Divider(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: _editProfile, child: const Text('Edit')),
            ],
          ),
          Text(payment.isEmpty ? 'No payment method saved' : payment),
        ],
      ),
    ),
  );
}
