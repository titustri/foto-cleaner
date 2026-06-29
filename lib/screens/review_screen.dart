import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/photo_service.dart';

class ReviewScreen extends StatefulWidget {
  final PhotoService photoService;

  const ReviewScreen({super.key, required this.photoService});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  List<AssetEntity> _currentBatch = [];
  final List<AssetEntity> _toDelete = [];

  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isDone = false;

  int _totalDeleted = 0;
  int _totalKept = 0;
  int _batchKey = 0; // force CardSwiper rebuild saat ganti batch

  @override
  void initState() {
    super.initState();
    _loadNextBatch();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadNextBatch() async {
    setState(() => _isLoading = true);

    final List<AssetEntity> batch = await widget.photoService.getNextBatch();

    if (batch.isEmpty) {
      setState(() {
        _isDone = true;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _currentBatch = batch;
      _toDelete.clear();
      _batchKey++;
      _isLoading = false;
    });
  }

  // Dipanggil tiap kali card di-swipe
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    final AssetEntity asset = _currentBatch[previousIndex];

    if (direction == CardSwiperDirection.left) {
      _toDelete.add(asset);
    } else if (direction == CardSwiperDirection.right) {
      _totalKept++;
    }

    // currentIndex null = semua card di batch ini sudah di-swipe
    if (currentIndex == null) {
      _executeDeletion();
    }

    return true;
  }

  Future<void> _executeDeletion() async {
    setState(() => _isDeleting = true);

    if (_toDelete.isNotEmpty) {
      final int count = _toDelete.length;
      await widget.photoService.deleteAssets(List.from(_toDelete));
      _totalDeleted += count;
    }

    setState(() => _isDeleting = false);

    if (widget.photoService.hasMore) {
      await _loadNextBatch();
    } else {
      setState(() => _isDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDone) return _buildDoneScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_isLoading || _isDeleting)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)))
            else
              Expanded(child: _buildCardArea()),
            _buildBottomHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final int reviewed = widget.photoService.currentOffset - _currentBatch.length +
        (_currentBatch.isEmpty ? 0 : 0);
    final int total = widget.photoService.totalCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),

          // Progress
          Column(
            children: [
              Text(
                '${widget.photoService.currentOffset} / $total foto',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : widget.photoService.currentOffset / total,
                  backgroundColor: Colors.white12,
                  color: Colors.white,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                const Icon(Icons.delete_outline, color: Colors.redAccent, size: 14),
                const SizedBox(width: 4),
                Text('$_totalDeleted', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ]),
              Row(children: [
                const Icon(Icons.favorite_outline, color: Colors.greenAccent, size: 14),
                const SizedBox(width: 4),
                Text('$_totalKept', style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: CardSwiper(
        key: ValueKey(_batchKey),
        controller: _swiperController,
        cardsCount: _currentBatch.length,
        onSwipe: _onSwipe,
        numberOfCardsDisplayed: _currentBatch.length < 3 ? _currentBatch.length : 3,
        backCardOffset: const Offset(30, 30),
        scale: 0.92,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
          return _buildPhotoCard(
            _currentBatch[index],
            horizontalOffsetPercentage,
          );
        },
      ),
    );
  }

  Widget _buildPhotoCard(AssetEntity asset, double horizontalOffset) {
    // Overlay warna berdasarkan arah swipe
    Color overlayColor = Colors.transparent;
    String overlayLabel = '';
    IconData overlayIcon = Icons.close;

    if (horizontalOffset < -0.1) {
      final double opacity = (-horizontalOffset).clamp(0.0, 0.6);
      overlayColor = Colors.red.withOpacity(opacity);
      overlayLabel = 'HAPUS';
      overlayIcon = Icons.delete_outline;
    } else if (horizontalOffset > 0.1) {
      final double opacity = horizontalOffset.clamp(0.0, 0.6);
      overlayColor = Colors.green.withOpacity(opacity);
      overlayLabel = 'SIMPAN';
      overlayIcon = Icons.favorite_outline;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Foto
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AssetEntityImage(
            asset,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(800),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.broken_image, color: Colors.white30, size: 48),
            ),
          ),
        ),

        // Swipe overlay
        if (overlayColor != Colors.transparent)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: overlayColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(overlayIcon, color: Colors.white, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      overlayLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Delete hint
          GestureDetector(
            onTap: () => _swiperController.swipe(CardSwiperDirection.left),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  SizedBox(width: 6),
                  Text('Hapus', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),

          // Keep hint
          GestureDetector(
            onTap: () => _swiperController.swipe(CardSwiperDirection.right),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Text('Simpan', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600)),
                  SizedBox(width: 6),
                  Icon(Icons.favorite_outline, color: Colors.greenAccent, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Selesai!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white08,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _summaryRow(Icons.delete_outline, Colors.redAccent, 'Dihapus', '$_totalDeleted foto'),
                      const Divider(color: Colors.white12, height: 24),
                      _summaryRow(Icons.favorite_outline, Colors.greenAccent, 'Disimpan', '$_totalKept foto'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Kembali ke Menu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
        const Spacer(),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
