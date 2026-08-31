import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Rasterizes [Logo Flower.svg] at high DPI — smooth edges on splash & loaders.
class FlowerLogoImageCache {
  FlowerLogoImageCache._();

  static const String asset = 'resources/Logo Flower.svg';
  static const double oversample = 3.5;

  static final Map<int, ui.Image> _images = {};
  static final Map<int, Future<ui.Image?>> _loading = {};

  static double hiSizeFor(BuildContext context, double displaySize) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (displaySize * oversample * dpr).clamp(displaySize * 2.5, 512);
  }

  static int _key(double hi) => hi.round();

  static ui.Image? imageFor(double hi) => _images[_key(hi)];

  static Future<ui.Image?> warmUp(double hi) {
    final key = _key(hi);
    if (_images.containsKey(key)) return Future.value(_images[key]);
    return _loading[key] ??= _load(hi, key);
  }

  static Future<ui.Image?> _load(double hi, int key) async {
    try {
      final pictureInfo = await vg.loadPicture(SvgAssetLoader(asset), null);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final iw = pictureInfo.size.width;
      final ih = pictureInfo.size.height;
      final scale = math.min(hi / iw, hi / ih);
      canvas.translate((hi - iw * scale) / 2, (hi - ih * scale) / 2);
      canvas.scale(scale);
      canvas.drawPicture(pictureInfo.picture);
      pictureInfo.picture.dispose();

      final picture = recorder.endRecording();
      final image = await picture.toImage(hi.toInt(), hi.toInt());
      _images[key]?.dispose();
      _images[key] = image;
      return image;
    } catch (_) {
      return null;
    } finally {
      _loading.remove(key);
    }
  }

  /// Downscales a hi-res raster for crisp display at [displaySize] logical px.
  static Widget smoothImage({
    required ui.Image image,
    required double displaySize,
    required double hi,
  }) {
    final downscale = displaySize / hi;
    return RepaintBoundary(
      child: SizedBox(
        width: displaySize,
        height: displaySize,
        child: ClipRect(
          clipBehavior: Clip.none,
          child: OverflowBox(
            alignment: Alignment.center,
            minWidth: hi,
            maxWidth: hi,
            minHeight: hi,
            maxHeight: hi,
            child: Transform.scale(
              scale: downscale,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              child: SizedBox(
                width: hi,
                height: hi,
                child: RawImage(
                  image: image,
                  width: hi,
                  height: hi,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
