import 'package:flutter/material.dart';

/// Logo "G" Google multi-warna tanpa aset eksternal.
///
/// Catatan: warna di sini adalah **warna brand resmi Google** (bukan token
/// desain SafeRoad), sehingga sengaja di-hardcode dan diisolasi hanya di
/// widget ini.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const SweepGradient(
          colors: [
            Color(0xFF4285F4), // biru
            Color(0xFF34A853), // hijau
            Color(0xFFFBBC05), // kuning
            Color(0xFFEA4335), // merah
            Color(0xFF4285F4), // biru (tutup gradien)
          ],
          stops: [0.0, 0.27, 0.5, 0.75, 1.0],
        ).createShader(bounds),
        child: const FittedBox(
          fit: BoxFit.contain,
          child: Text(
            'G',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
