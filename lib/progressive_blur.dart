import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

/// A widget that applies a progressive blur effect to its child.
///
/// Simplest way to use it is to use the default constructor and provide a
/// [LinearGradientBlur] object. See the documentation of that class for
/// more information.
///
/// Alternatively, you can apply the blur as a blur texture via the `.custom()`
/// constructor. The blur texture can be thought of as a strength map for the
/// blur (`final_sigma = sigma * texture(x, y).r`). You can supply your own blur
/// texture to create custom blur effects.
///
/// The blur is applied in two passes: first horizontally and then vertically.
///
/// The blur shader should be precached before using this widget to avoid a
/// pop-in effect. You can do this by calling [ProgressiveBlurWidget.precache] as
/// early as possible in your app (e.g. in `main()`).
/// Selects which side of the kernel to sample from when blurring along an
/// axis. `symmetric` samples both sides (default Gaussian). `positive` samples
/// only in the positive axis direction (right/down). `negative` samples only in
/// the negative axis direction (left/up).
enum BlurSide {
  symmetric,
  positive,
  negative,
}

/// Determines how the blur map (texture) is interpreted.
///
/// - [modulateSigma]: The map value scales the blur sigma per-pixel.
/// - [blendWithBlurred]: A constant-sigma blur is computed then blended with
///   the original using the map value. This avoids directional smearing and
///   usually looks closer to a "progressive" Gaussian.
enum BlurMapMode {
  modulateSigma,
  blendWithBlurred,
}

/// Edge of a rectangle used for simple one-sided blur specifications.
enum BlurEdge {
  top,
  bottom,
  left,
  right,
}

class ProgressiveBlurWidget extends StatefulWidget {
  const ProgressiveBlurWidget({
    super.key,
    required this.linearGradientBlur,
    required this.sigma,
    required this.child,
    this.blurTextureDimensions = 128,
    this.tintColor = Colors.transparent,
    this.enableHorizontalPass = true,
    this.enableVerticalPass = true,
    this.horizontalSide = BlurSide.symmetric,
    this.verticalSide = BlurSide.symmetric,
    this.mapMode = BlurMapMode.blendWithBlurred,
    this.mapExponent = 2.0,
  }) : blurTexture = null;

  const ProgressiveBlurWidget.custom({
    super.key,
    required this.blurTexture,
    required this.sigma,
    required this.child,
    this.tintColor = Colors.transparent,
    this.enableHorizontalPass = true,
    this.enableVerticalPass = true,
    this.horizontalSide = BlurSide.symmetric,
    this.verticalSide = BlurSide.symmetric,
    this.mapMode = BlurMapMode.blendWithBlurred,
    this.mapExponent = 2.0,
  })  : linearGradientBlur = null,
        // Irrelevant in case of a custom blur texture
        blurTextureDimensions = -1;

  /// Asset key of the shader.
  static const _shaderAssetKey =
      'packages/progressive_blur/lib/shaders/progressive_blur.frag';

  /// Precaches the blur shader so that it can be used synchronously later.
  /// This should be called as early as possible in your app (e.g. in `main()`).
  static Future<void> precache() {
    return ShaderBuilder.precacheShader(_shaderAssetKey);
  }

  /// A simple constructor that allows to specify a linear gradient blur.
  final LinearGradientBlur? linearGradientBlur;

  /// Dimensions of the blur texture. If not provided, it will be set to 128.
  ///
  /// If you notice that the blur appears to be blocky, you can try increasing
  /// this value.
  final int blurTextureDimensions;

  /// The blur texture to be used as the blur strength map.
  final ui.Image? blurTexture;

  /// The standard deviation of the Gaussian blur.
  final double sigma;

  /// Tint color to apply to the blurred area.
  final Color tintColor;

  /// Enables the horizontal blur pass. Defaults to `true`.
  final bool enableHorizontalPass;

  /// Enables the vertical blur pass. Defaults to `true`.
  final bool enableVerticalPass;

  /// Which horizontal side to sample from (left/right) when blurring
  /// horizontally. Defaults to [BlurSide.symmetric].
  final BlurSide horizontalSide;

  /// Which vertical side to sample from (top/bottom) when blurring vertically.
  /// Defaults to [BlurSide.symmetric].
  final BlurSide verticalSide;

  /// How to interpret the blur texture / map. Defaults to
  /// [BlurMapMode.blendWithBlurred].
  final BlurMapMode mapMode;

  /// Response curve exponent applied to the blur map value before use.
  /// 1.0 = linear, <1.0 = softer falloff, >1.0 = sharper edge. Default 2.0.
  final double mapExponent;

  /// The widget to be blurred.
  final Widget child;

  @override
  State<ProgressiveBlurWidget> createState() => _ProgressiveBlurWidgetState();
}

class _ProgressiveBlurWidgetState extends State<ProgressiveBlurWidget> {
  /// The blur texture that this widget manages.
  ui.Image? _managedBlurTexture;

  @override
  void initState() {
    super.initState();
    _maybeCreateBlurTexture();
  }

  /// Disposes of the old blur texture and creates a new one if necessary.
  void _maybeCreateBlurTexture() {
    _managedBlurTexture?.dispose();

    if (widget.linearGradientBlur != null) {
      _managedBlurTexture = widget.linearGradientBlur!.createTexture(
        width: widget.blurTextureDimensions,
        height: widget.blurTextureDimensions,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProgressiveBlurWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.blurTexture != null && oldWidget.blurTexture == null) {
      _managedBlurTexture?.dispose();
      _managedBlurTexture = null;
      return;
    }

    var shouldCreateBlurTexture = false;

    if (widget.blurTextureDimensions != oldWidget.blurTextureDimensions) {
      shouldCreateBlurTexture = true;
    }

    if (widget.linearGradientBlur != oldWidget.linearGradientBlur) {
      shouldCreateBlurTexture = true;
    }

    if (shouldCreateBlurTexture) {
      _maybeCreateBlurTexture();
    }
  }

  @override
  void dispose() {
    _managedBlurTexture?.dispose();
    super.dispose();
  }

  ui.Image get blurTexture => widget.blurTexture ?? _managedBlurTexture!;

  @override
  Widget build(BuildContext context) {
    // The output texture should be scaled by the device pixel ratio.
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    double _sideToSign(BlurSide side) {
      switch (side) {
        case BlurSide.positive:
          return 1.0;
        case BlurSide.negative:
          return -1.0;
        case BlurSide.symmetric:
        default:
          return 0.0;
      }
    }

    double _mapModeToFloat(BlurMapMode mode) {
      switch (mode) {
        case BlurMapMode.modulateSigma:
          return 0.0;
        case BlurMapMode.blendWithBlurred:
          return 1.0;
      }
    }

    return RepaintBoundary(
      child: ShaderBuilder(
        (context, shader, child) {
          return AnimatedSampler(
            (image, size, canvas) {
              final scaledSize = size * devicePixelRatio;

              // First do X-axis pass
              final firstPassRecorder = ui.PictureRecorder();
              final firstPassCanvas = Canvas(firstPassRecorder);

              shader.setImageSampler(0, image); // child_texture
              shader.setImageSampler(1, blurTexture); // blur_texture
              shader.setImageSampler(2, image); // original_texture (unused in pass 1)

              shader.setFloat(0, scaledSize.width); // child_size.x
              shader.setFloat(1, scaledSize.height); // child_size.y
              shader.setFloat(
                2,
                widget.enableHorizontalPass ? widget.sigma : 0.0,
              ); // blur_sigma (horizontal)
              shader.setFloat(3, 0.0); // blur_direction (horizontal)
              shader.setFloat(4, _sideToSign(widget.horizontalSide)); // side
              shader.setFloat(5, _mapModeToFloat(widget.mapMode)); // blur_map_mode
              shader.setFloat(6, 0.0); // is_final_pass
              shader.setFloat(7, widget.tintColor.r); // tint.r
              shader.setFloat(8, widget.tintColor.g); // tint.g
              shader.setFloat(9, widget.tintColor.b); // tint.b
              shader.setFloat(10, widget.tintColor.a); // tint.a
              shader.setFloat(11, widget.mapExponent); // map_exponent

              // Draw the first pass
              final paint = Paint()..shader = shader;
              firstPassCanvas.drawRect(Offset.zero & scaledSize, paint);

              // End the first pass and get the image reference
              final firstPassPicture = firstPassRecorder.endRecording();
              final firstPassImage = firstPassPicture.toImageSync(
                scaledSize.width.toInt(),
                scaledSize.height.toInt(),
              );

              // Then do Y-axis pass
              shader.setImageSampler(0, firstPassImage); // child_texture
              shader.setImageSampler(1, blurTexture); // blur_texture (rebind for clarity)
              shader.setImageSampler(2, image); // original_texture for final blend
              shader.setFloat(
                2,
                widget.enableVerticalPass ? widget.sigma : 0.0,
              ); // blur_sigma (vertical)
              shader.setFloat(3, 1.0); // blur_direction (vertical)
              shader.setFloat(4, _sideToSign(widget.verticalSide)); // side
              shader.setFloat(5, _mapModeToFloat(widget.mapMode)); // blur_map_mode
              shader.setFloat(6, 1.0); // is_final_pass
              shader.setFloat(11, widget.mapExponent); // map_exponent

              // Scale the canvas back so that we can apply the pixel ratio
              // scaling.
              canvas.scale(1 / devicePixelRatio);
              canvas.drawRect(Offset.zero & scaledSize, paint);

              // Dispose the first pass resources.
              firstPassPicture.dispose();
              firstPassImage.dispose();
            },
            child: child!,
          );
        },
        assetKey: ProgressiveBlurWidget._shaderAssetKey,
        child: widget.child,
      ),
    );
  }
}

/// Parameters to use to create a blur texture for the [ProgressiveBlurWidget].
///
/// By itself it can only create a linear gradient blur. For more complex blur
/// effects, you can create a custom blur texture and provide it to the widget.
class LinearGradientBlur {
  const LinearGradientBlur({
    required this.values,
    required this.stops,
    required this.start,
    required this.end,
  });

  /// Convenience factory: create a simple one-sided blur that starts at
  /// `startFraction` and ends at `endFraction` measured along the axis of the
  /// given [edge]. Fractions are in [0, 1], where 0 = top/left and 1 =
  /// bottom/right.
  factory LinearGradientBlur.fromEdge({
    required BlurEdge edge,
    required double startFraction,
    double endFraction = 1.0,
    Curve curve = Curves.linear,
    int samples = 2,
    bool strongAtEdge = true,
  }) {
    // Clamp inputs
    startFraction = startFraction.clamp(0.0, 1.0);
    endFraction = endFraction.clamp(0.0, 1.0);

    // Interpret fractions relative to the chosen edge:
    // For top/left: 0.0 = near the edge, 1.0 = far opposite
    // For bottom/right: convert to top/left space by flipping the axis.
    bool flip = edge == BlurEdge.bottom || edge == BlurEdge.right;
    double s = flip ? (1.0 - endFraction) : startFraction;
    double e = flip ? (1.0 - startFraction) : endFraction;

    // Ensure ascending order in [0,1]
    if (e < s) {
      final t = s;
      s = e;
      e = t;
    }

    final bool horizontal = edge == BlurEdge.left || edge == BlurEdge.right;
    final Alignment a = horizontal ? Alignment.centerLeft : Alignment.topCenter;
    final Alignment b = horizontal ? Alignment.centerRight : Alignment.bottomCenter;

    samples = samples.clamp(2, 64);
    final span = e - s;
    final stops = List<double>.generate(
      samples,
      (i) => s + span * (i / (samples - 1)),
    );
    final values = List<double>.generate(
      samples,
      (i) {
        final t = i / (samples - 1);
        final v = curve.transform(t);
        // If strongAtEdge, map 1.0 at the chosen edge and fade to 0.0 away
        // from it; otherwise keep the natural 0..1 ramp.
        return strongAtEdge ? (1.0 - v) : v;
      },
    );

    return LinearGradientBlur(
      values: values,
      stops: stops,
      start: a,
      end: b,
    );
  }

  /// List of values to be used in the gradient. 1.0 represents maximum blur,
  /// 0.0 represents no blur.
  final List<double> values;

  /// List of stops to be used in the gradient. Must be the same length as
  /// [values].
  final List<double> stops;

  /// The alignment of the start of the gradient.
  final Alignment start;

  /// The alignment of the end of the gradient.
  final Alignment end;

  /// Creates the blur texture. By default, width and height are set to 128.
  ui.Image createTexture({int width = 128, int height = 128}) {
    final size = Size(width.toDouble(), height.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final gradient = ui.Gradient.linear(
      start.alongSize(size),
      end.alongSize(size),
      values.map((v) => Color.fromARGB(255, (v * 255).round(), 0, 0)).toList(),
      stops,
    );

    final paint = ui.Paint()..shader = gradient;
    canvas.drawRect(Offset.zero & size, paint);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(width, height);

    return image;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LinearGradientBlur &&
        listEquals(other.values, values) &&
        listEquals(other.stops, stops) &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hashAll([...values, ...stops, start, end]);
}
