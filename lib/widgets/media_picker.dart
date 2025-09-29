import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class MediaPickerController extends GetxController {
  final ImagePicker _imagePicker = ImagePicker();

  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<File?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick video: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<File?> pickDocument() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'txt',
          'xls',
          'xlsx',
          'ppt',
          'pptx'
        ],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick document: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Disabled',
          'Location services are disabled. Please enable them to share location.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permissions are denied',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Denied',
          'Location permissions are permanently denied, we cannot request permissions.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get current location: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }
}

class MediaPickerDialog extends StatelessWidget {
  const MediaPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MediaPickerController());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Share',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),

          // First row of options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaOption(
                icon: Icons.photo_camera,
                label: 'Camera',
                color: Colors.blue,
                onTap: () async {
                  Get.back();
                  final file =
                      await controller.pickImage(source: ImageSource.camera);
                  if (file != null) {
                    Get.back(result: {'type': 'image', 'file': file});
                  }
                },
              ),
              _buildMediaOption(
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.green,
                onTap: () async {
                  Get.back();
                  final file =
                      await controller.pickImage(source: ImageSource.gallery);
                  if (file != null) {
                    Get.back(result: {'type': 'image', 'file': file});
                  }
                },
              ),
              _buildMediaOption(
                icon: Icons.videocam,
                label: 'Video',
                color: Colors.red,
                onTap: () async {
                  Get.back();
                  final file = await controller.pickVideo();
                  if (file != null) {
                    Get.back(result: {'type': 'video', 'file': file});
                  }
                },
              ),
              _buildMediaOption(
                icon: Icons.description,
                label: 'Document',
                color: Colors.orange,
                onTap: () async {
                  Get.back();
                  final file = await controller.pickDocument();
                  if (file != null) {
                    Get.back(result: {'type': 'document', 'file': file});
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Second row of options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMediaOption(
                icon: Icons.location_on,
                label: 'Location',
                color: Colors.purple,
                onTap: () async {
                  Get.back();
                  final position = await controller.getCurrentLocation();
                  if (position != null) {
                    Get.back(result: {
                      'type': 'location',
                      'latitude': position.latitude,
                      'longitude': position.longitude,
                    });
                  }
                },
              ),
              _buildMediaOption(
                icon: Icons.mic,
                label: 'Voice',
                color: Colors.teal,
                onTap: () {
                  Get.back();
                  Get.back(result: {'type': 'voice'});
                },
              ),
              _buildMediaOption(
                icon: Icons.emoji_emotions,
                label: 'Sticker',
                color: Colors.pink,
                onTap: () {
                  Get.back();
                  Get.back(result: {'type': 'sticker'});
                },
              ),
              _buildMediaOption(
                icon: Icons.contact_phone,
                label: 'Contact',
                color: Colors.indigo,
                onTap: () {
                  Get.back();
                  Get.back(result: {'type': 'contact'});
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to show the media picker
Future<Map<String, dynamic>?> showMediaPicker() {
  return Get.bottomSheet<Map<String, dynamic>>(
    const MediaPickerDialog(),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}
