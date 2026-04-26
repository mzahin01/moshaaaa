import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../widgets/risk_badge.dart';
import '../../../../widgets/stat_card.dart';
import '../../../routes/app_pages.dart';
import '../controllers/result_controller.dart';

class ResultView extends GetView<ResultController> {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> recommendations = controller.recommendations;
    final double? latitude = controller.latitude;
    final double? longitude = controller.longitude;

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildAnnotatedImage(),
                    const SizedBox(height: 16),
                    RiskBadge(riskLevel: controller.riskLevel),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: StatCard(
                            title: 'Water Coverage',
                            value:
                                '${controller.waterCoverage.toStringAsFixed(1)}%',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Detections',
                            value: '${controller.detections}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Recommendations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    if (recommendations.isEmpty)
                      const Text('No recommendations returned by the model.'),
                    ...recommendations.map(
                      (String recommendation) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          title: Text(recommendation),
                        ),
                      ),
                    ),
                    if (latitude != null && longitude != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Text(
                        'Detected Location',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text('Latitude: ${latitude.toStringAsFixed(6)}'),
                              Text(
                                'Longitude: ${longitude.toStringAsFixed(6)}',
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _openMap(latitude, longitude),
                                icon: const Icon(Icons.map),
                                label: const Text('View on Google Maps'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Get.offAllNamed(Routes.home),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Scan Another'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnotatedImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 280,
        width: double.infinity,
        color: Colors.black12,
        child: controller.annotatedBytes == null
            ? const Center(child: Text('Annotated image unavailable'))
            : Image.memory(controller.annotatedBytes!, fit: BoxFit.cover),
      ),
    );
  }

  Future<void> _openMap(double latitude, double longitude) async {
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps?q=$latitude,$longitude',
    );

    final bool launched = await launchUrl(
      mapsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      Get.snackbar(
        'Map Error',
        'Could not launch Google Maps.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
