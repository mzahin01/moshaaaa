import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final RxBool isPicking = false.obs;

  Future<void> pickImage(ImageSource source) async {
    if (isPicking.value) {
      return;
    }

    isPicking.value = true;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (image == null) {
        return;
      }

      final String fileName = image.name.isEmpty
          ? 'scan_image.jpg'
          : image.name;
      final List<int> imageBytes = await image.readAsBytes();

      await Get.toNamed(
        Routes.analysis,
        arguments: <String, dynamic>{
          'imageBytes': imageBytes,
          'fileName': fileName,
        },
      );
    } catch (error) {
      Get.snackbar(
        'Image Selection Failed',
        'Could not pick image: $error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPicking.value = false;
    }
  }
}
