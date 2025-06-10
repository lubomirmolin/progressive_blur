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
  tintColor: Colors.orange.withOpacity(0.3), // Optional tint color
  child: ...
);

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

## Additional information

Feel free to report bugs/issues on GitHub.

If you have questions, you can contact me directly at `kk.erzhan@gmail.com`.

Credits:
- https://www.shadertoy.com/view/Mfd3DM - an inspiration for the blur shader
- [`flutter_shaders`](https://pub.dev/packages/flutter_shaders) - a great library for working with shaders in Flutter