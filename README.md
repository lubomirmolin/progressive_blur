![Demo image](images/image.png)

> [!NOTE]
> Early version of the project. The performance may be suboptimal, and the APIs may change in the future.

An iOS-like progressive blur implementation for Flutter.

## Usage

See the example folder for a complete example.

> [!CAUTION]
> The CanvasKit web performance seems to be terrible. I'm not exactly sure why at the moment. However, `skwasm` performs much better.

```dart
import 'package:progressive_blur/progressive_blur.dart';

// Simple gradient blur with optional tint
ProgressiveBlurWidget(
  sigma: 24.0,
  linearGradientBlur: const LinearGradientBlur(
    values: [0, 1], // 0 - no blur, 1 - full blur
    stops: [0.5, 0.8],
    start: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
  // mapMode defaults to BlurMapMode.blendWithBlurred
  tintColor: Colors.orange.withOpacity(0.3), // Optional tint color
  child: ...
);

// Or use the simpler edge-based shorthand:
ProgressiveBlurWidget(
  sigma: 24.0,
  linearGradientBlur: LinearGradientBlur.fromEdge(
    edge: BlurEdge.bottom,
    // Fractions are measured FROM the chosen edge.
    // Here: start 20% up from bottom, fully blurred by 80% up.
    startFraction: 0.2,
    endFraction: 0.8,
    curve: Curves.easeIn,
    samples: 12,
    strongAtEdge: true, // 1.0 at edge → 0.0 away
  ),
  mapExponent: 1.0,        // optional: 1.0 = linear mask (softer)
  child: ...,
)

// Advanced: custom blur texture
//
// You can create a custom blur texture using the Flutter's Canvas API. Note that the red channel controls the blur strength (0 - no blur, 255 - full blur).
ProgressiveBlurWidget.custom(
  sigma: 24.0,
  blurTexture: [instance of ui.Image],
  tintColor: Colors.purple.withOpacity(0.4), // Optional tint color
  child: ...,
)
```

### Map modes

The blur map can be used in two ways:

- `blendWithBlurred` (default): compute a constant-sigma Gaussian blur and blend it with the original using the map as alpha. Produces a smooth progressive look (recommended).
- `modulateSigma`: scale sigma per-pixel by the map value. This can introduce directional smearing near sharp transitions; use only if you want that effect.

Tip: for a Gaussian look, keep both passes enabled. Disabling one pass will create a directional blur.

### One-sided blur (directional kernel)

You can constrain the Gaussian kernel to sample only one side along an axis.

- Horizontal: left/right via `horizontalSide`.
- Vertical: top/bottom via `verticalSide`.
- Optionally disable a pass entirely via `enableHorizontalPass` / `enableVerticalPass`.

Examples:

```dart
// Bottom-only blur, vertical pass only
ProgressiveBlurWidget(
  sigma: 24.0,
  linearGradientBlur: LinearGradientBlur.fromEdge(
    edge: BlurEdge.bottom,
    startFraction: 0.8,
  ),
  enableHorizontalPass: false,     // no horizontal blur
  enableVerticalPass: true,
  verticalSide: BlurSide.positive, // positive = downward (bottom)
  child: ...,
);

// Left-only horizontal blur while keeping vertical symmetric
ProgressiveBlurWidget(
  sigma: 18.0,
  linearGradientBlur: const LinearGradientBlur(
    values: [0, 1],
    stops: [0.6, 1.0],
    start: Alignment.centerLeft,
    end: Alignment.centerRight,
  ),
  horizontalSide: BlurSide.negative, // negative = left
  child: ...,
);
```

## Additional information

Feel free to report bugs/issues on GitHub.

If you have questions, you can contact me directly at `kk.erzhan@gmail.com`.

Credits:
- https://www.shadertoy.com/view/Mfd3DM - an inspiration for the blur shader
- [`flutter_shaders`](https://pub.dev/packages/flutter_shaders) - a great library for working with shaders in Flutter
