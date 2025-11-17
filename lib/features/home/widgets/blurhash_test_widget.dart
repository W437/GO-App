import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

/// Quick test widget to see blurhash in action
/// Add this to your home screen temporarily to test
class BlurhashTestWidget extends StatelessWidget {
  const BlurhashTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Blurhash Test', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text('Sample 1', style: TextStyle(fontSize: 10)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const BlurHash(
                            hash: 'LGF5]+Yk^6#M@-5c,1J5@[or[Q6.',
                            imageFit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Sample 2', style: TextStyle(fontSize: 10)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const BlurHash(
                            hash: 'L6Pj0^jE.AyE_3t7t7R**0o#DgR4',
                            imageFit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      const Text('Sample 3', style: TextStyle(fontSize: 10)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const BlurHash(
                            hash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
                            imageFit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
