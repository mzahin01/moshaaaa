import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: <Widget>[
            Icon(Icons.pest_control),
            SizedBox(width: 8),
            Text('MosquitoScan'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              Icons.bug_report,
              size: 84,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Detect mosquito breeding spots from a photo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 28),
            Obx(
              () => SizedBox(
                height: 68,
                child: FilledButton.icon(
                  onPressed: controller.isPicking.value
                      ? null
                      : () => controller.pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera, size: 28),
                  label: const Text('Take Photo'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => SizedBox(
                height: 68,
                child: FilledButton.tonalIcon(
                  onPressed: controller.isPicking.value
                      ? null
                      : () => controller.pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 28),
                  label: const Text('Upload from Gallery'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
