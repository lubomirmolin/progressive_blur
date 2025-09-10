import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:progressive_blur/progressive_blur.dart';

Future<void> main() async {
  await ProgressiveBlurWidget.precache();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SimpleGridPage(),
    );
  }
}

class SimpleGridPage extends StatelessWidget {
  const SimpleGridPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progressive Blur Grid')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = (constraints.maxWidth / 200).floor().clamp(1, 10);
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 200 / 300,
            ),
            itemCount: 20,
            itemBuilder: (context, index) => const _ImageCard(),
          );
        },
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard();

  @override
  Widget build(BuildContext context) {
    return ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: 24,
        cornerSmoothing: 0,
      ),
      child: ProgressiveBlurWidget(
        sigma: 20,
        mapExponent: 0.5, // softer than default 2.0
        tintColor: Colors.green.withOpacity(0.58),
        linearGradientBlur: LinearGradientBlur.fromEdge(
          edge: BlurEdge.bottom,
          startFraction: 0.7, // no blur until 15% height
          endFraction: 1, // full blur by 55%
          curve: Curves.easeIn, // smooth ramp
          samples: 100, // multi-stop sampling
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black38],
            ),
          ),
          // child: Text('Textsdfsfsafas'),
          child: Image.asset(
            'assets/test.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
