import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

const _kChulogoAssetPath = 'assets/logo/chullogo.png';

/// 디코딩·배경 치환은 한 번만 수행합니다.
Future<Uint8List>? _processedChulogoFuture;

Future<Uint8List> _loadChulogoWithWhiteBackground() async {
  final bd = await rootBundle.load(_kChulogoAssetPath);
  final raw = Uint8List.fromList(bd.buffer.asUint8List());
  final decoded = img.decodeImage(raw);
  if (decoded == null) return raw;
  _replaceLightNeutralWithWhite(decoded);
  return Uint8List.fromList(img.encodePng(decoded));
}

/// 채도가 거의 없고 밝기가 높은 픽셀(연한 회색 배경)만 흰색으로 바꿉니다. 주황 등 컬러는 유지합니다.
void _replaceLightNeutralWithWhite(img.Image image) {
  const chromaMax = 34;
  const lightnessMin = 188;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final a = p.a.toInt();
      if (a < 24) continue;
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final maxc = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minc = r < g ? (r < b ? r : b) : (g < b ? g : b);
      if (maxc - minc > chromaMax) continue;
      if (maxc < lightnessMin) continue;
      image.setPixelRgba(x, y, 255, 255, 255, a);
    }
  }
}

/// 앱 공식 로고. 에셋의 연한 회색 배경은 런타임에 흰색으로 치환해 표시합니다.
class AppLogoImage extends StatelessWidget {
  const AppLogoImage({
    super.key,
    this.size = 84,
    this.borderRadius = 22,
  });

  final double size;
  final double borderRadius;

  static const String assetPath = _kChulogoAssetPath;

  @override
  Widget build(BuildContext context) {
    _processedChulogoFuture ??= _loadChulogoWithWhiteBackground();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: FutureBuilder<Uint8List>(
          future: _processedChulogoFuture,
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            if (bytes != null) {
              return Image.memory(
                bytes,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              );
            }
            return Image.asset(
              assetPath,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            );
          },
        ),
      ),
    );
  }
}
