import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../services/live_session_service.dart';

class LiveDropPage extends StatefulWidget {
  final String sessionId;
  const LiveDropPage({super.key, required this.sessionId});

  @override
  State<LiveDropPage> createState() => _LiveDropPageState();
}

class _LiveDropPageState extends State<LiveDropPage> {
  final service = LiveSessionService();
  late Future<Map<String, dynamic>> sessionFuture;
  VideoPlayerController? videoController;

  @override
  void initState() {
    super.initState();
    sessionFuture = service.fetch(widget.sessionId);
    service.presence(sessionId: widget.sessionId, joining: true);
  }

  @override
  void dispose() {
    service.presence(sessionId: widget.sessionId, joining: false);
    videoController?.dispose();
    super.dispose();
  }

  Future<void> _setStatus(String status) async {
    await service.update(widget.sessionId, status);
    if (!mounted) return;
    setState(() => sessionFuture = service.fetch(widget.sessionId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session ${status == 'live' ? 'started' : 'ended'}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Live Drop')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: sessionFuture,
      builder: (context, snapshot) {
        final session = snapshot.data ?? const <String, dynamic>{};
        final status = session['status'] ?? 'scheduled';
        final streamUrl = session['streamUrl'] as String?;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session['title'] ?? 'Live Drop'}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('Hosted by ${session['hostType'] ?? 'hive member'}'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.red, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          status.toString().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text('${session['viewerCount'] ?? 0} viewers'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _videoPanel(streamUrl, status.toString()),
            const SizedBox(height: 16),
            _product(session),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: status == 'scheduled'
                        ? () => _setStatus('live')
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Live'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: status == 'live'
                        ? () => _setStatus('completed')
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('End Live'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  Widget _videoPanel(String? streamUrl, String status) {
    if (streamUrl == null || streamUrl.isEmpty) {
      return Card(
        color: const Color(0xFF2B2B2B),
        child: const SizedBox(
          height: 240,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  color: Colors.white70,
                  size: 54,
                ),
                SizedBox(height: 12),
                Text(
                  'Live video is not connected yet.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure an HLS or WebRTC stream URL to go live.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }
    videoController ??= VideoPlayerController.networkUrl(Uri.parse(streamUrl));
    return FutureBuilder<void>(
      future: videoController!.initialize().then((_) {
        if (status == 'live' && !videoController!.value.isPlaying)
          videoController!.play();
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        return AspectRatio(
          aspectRatio: videoController!.value.aspectRatio,
          child: VideoPlayer(videoController!),
        );
      },
    );
  }

  Widget _product(Map<String, dynamic> session) {
    final productName = '${session['product'] ?? 'Featured product'}';
    final image = '${session['image'] ?? 'assets/frenzybees_logo.png'}';
    final price = (session['price'] as num?)?.toDouble() ?? 0;
    final cartItem = CartItem(name: productName, price: price, image: image);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Image.asset(
              image,
              width: 112,
              height: 112,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.shopping_bag, size: 64),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Featured product',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'RM${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Earn ${session['nectar'] ?? 0} Nectar • In stock',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<CartProvider>().addItem(cartItem);
                      Navigator.pushNamed(
                        context,
                        '/checkout',
                        arguments: {
                          'sessionId': widget.sessionId,
                          'hostId': session['hostId'],
                        },
                      );
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Buy Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
