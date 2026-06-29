import 'package:flutter/material.dart';
import '../services/photo_service.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PhotoService _photoService = PhotoService();
  bool _isInitializing = false;
  String? _errorMessage;

  Future<void> _startReview() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final bool hasPermission = await _photoService.requestPermission();

    if (!hasPermission) {
      setState(() {
        _errorMessage =
            'Izin ditolak.\nBuka Pengaturan → Aplikasi → Foto Cleaner\n→ Izin → Foto → Izinkan';
        _isInitializing = false;
      });
      return;
    }

    await _photoService.initialize();

    if (_photoService.totalCount == 0) {
      setState(() {
        _errorMessage = 'Tidak ada foto ditemukan di perangkat ini.';
        _isInitializing = false;
      });
      return;
    }

    setState(() => _isInitializing = false);

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(photoService: _photoService),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                const Text(
                  'Foto Cleaner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Swipe kanan = Simpan  •  Swipe kiri = Hapus',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Info box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 16),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Foto ditampilkan dari yang terlama.\n'
                          'Konfirmasi hapus muncul per 20 foto.',
                          style: TextStyle(color: Colors.amber, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Start button
                if (_isInitializing)
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _startReview,
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text(
                        'Mulai Review Foto',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
