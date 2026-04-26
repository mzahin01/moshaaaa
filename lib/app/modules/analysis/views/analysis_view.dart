import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/analysis_controller.dart';

class AnalysisView extends GetView<AnalysisController> {
  const AnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 280,
                child: controller.imageBytes.isEmpty
                    ? const ColoredBox(
                        color: Colors.black12,
                        child: Center(
                          child: Text('Selected image unavailable'),
                        ),
                      )
                    : Image.memory(controller.imageBytes, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => controller.isAnalyzing.value
                  ? const Column(
                      children: <Widget>[
                        Center(child: CircularProgressIndicator()),
                        SizedBox(height: 14),
                        Text(
                          'Analyzing... (may take 30-60s on first run)',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : FilledButton.icon(
                      onPressed: controller.startAnalysis,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Analysis'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
