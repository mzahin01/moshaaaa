import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

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
    final double possibility = controller.possibilityPercent;

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
                    StatCard(
                      title: 'Possibility',
                      value: '${possibility.toStringAsFixed(0)}%',
                    ),
                    const SizedBox(height: 16),
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
                        'Photo Location',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(latitude, longitude),
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: <Widget>[
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.moshaaaa',
                              ),
                              MarkerLayer(
                                markers: <Marker>[
                                  Marker(
                                    point: LatLng(latitude, longitude),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
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
}
