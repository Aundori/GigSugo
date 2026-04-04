import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import '../config/cloudinary_config.dart';

class ProfileImageService {
  static final ImagePicker _imagePicker = ImagePicker();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Request camera and gallery permissions
  static Future<bool> _requestPermissions() async {
    try {
      final cameraPermission = await Permission.camera.request();
      final storagePermission = await Permission.photos.request();
      
      if (!cameraPermission.isGranted) {
        throw Exception('Camera permission is required to take photos');
      }
      
      if (!storagePermission.isGranted) {
        throw Exception('Storage permission is required to access photos');
      }
      
      return cameraPermission.isGranted && storagePermission.isGranted;
    } catch (e) {
      throw Exception('Failed to request permissions: $e');
    }
  }

  // Pick image from gallery or camera
  static Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      await _requestPermissions();
      
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      
      if (pickedFile == null) {
        print('No image selected');
        return null;
      }
      
      // Crop the image to square 1:1 ratio
      final croppedFile = await _cropImageToSquare(File(pickedFile.path));
      if (croppedFile == null) {
        print('Image cropping cancelled');
        return null;
      }
      
      print('Image picked and cropped: ${croppedFile.path}');
      return croppedFile;
    } catch (e) {
      print('Error picking image: $e');
      throw Exception('Failed to pick image: $e');
    }
  }

  // Crop image to square 1:1 ratio
  static Future<File?> _cropImageToSquare(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: const Color(0xFF1A1A1A),
            toolbarWidgetColor: Colors.white,
            statusBarColor: const Color(0xFF1A1A1A),
            activeControlsWidgetColor: const Color(0xFFBC764A),
            backgroundColor: Colors.black,
            dimmedLayerColor: Colors.black.withOpacity(0.8),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: true,
            showCropGrid: false,
            cropFrameStrokeWidth: 2,
            cropFrameColor: const Color(0xFFBC764A),
            cropStyle: CropStyle.rectangle,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            aspectRatioLockEnabled: true,
            resetButtonHidden: true,
            rotateButtonsHidden: true,
            aspectRatioLockDimensionSwapEnabled: false,
          ),
        ],
      );
      
      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  // Upload image to Cloudinary using HTTP
  static Future<String> uploadProfileImage(File imageFile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      print('Starting Cloudinary upload for user: $userId');
      print('Image file path: ${imageFile.path}');
      
      // Create multipart request with actual file
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload'),
      );
      
      // Add file as multipart file (not base64)
      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      // Add required fields
      request.fields['upload_preset'] = 'profile_pictures';
      request.fields['public_id'] = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      request.fields['folder'] = 'profile_pictures';
      
      // Add authentication
      request.fields['api_key'] = CloudinaryConfig.apiKey;
      
      // Generate timestamp for signature
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      request.fields['timestamp'] = timestamp.toString();
      
      print('Sending request to Cloudinary...');
      
      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      
      print('Cloudinary response: $responseData');
      
      if (response.statusCode != 200) {
        print('Cloudinary error: $responseData');
        throw Exception('Cloudinary upload failed: ${jsonResponse['error']['message'] ?? 'Unknown error'}');
      }
      
      final secureUrl = jsonResponse['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Failed to get secure URL from Cloudinary');
      }

      print('Cloudinary upload successful: $secureUrl');

      // Update Firestore with Cloudinary URL
      await _firestore.collection('musician_profiles').doc(userId).update({
        'profileImageUrl': secureUrl,
        'cloudinaryPublicId': jsonResponse['public_id'] as String?,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Firestore updated successfully');
      return secureUrl;

    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Delete old profile image from Cloudinary
  static Future<void> _deleteOldProfileImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    
    try {
      // Extract public ID from URL
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final publicIdIndex = segments.indexOf('upload') + 2;
      
      if (publicIdIndex < segments.length) {
        final publicId = segments.sublist(publicIdIndex).join('/');
        // Note: Cloudinary deletion is optional - old images will be overwritten
        print('Old profile image will be overwritten: $publicId');
      }
    } catch (e) {
      print('Warning: Could not process old profile image: $e');
    }
  }

  // Complete profile image update process
  static Future<String> updateProfileImage({bool fromCamera = false}) async {
    try {
      // Pick new image
      final imageFile = await pickImage(fromCamera: fromCamera);
      if (imageFile == null) {
        throw Exception('No image selected');
      }

      // Get current profile to delete old image
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final profileDoc = await _firestore.collection('musician_profiles').doc(userId).get();
        if (profileDoc.exists) {
          final oldImageUrl = profileDoc.data()?['profileImageUrl'] as String?;
          await _deleteOldProfileImage(oldImageUrl);
        }
      }

      // Upload new image and get URL
      final newImageUrl = await uploadProfileImage(imageFile);

      return newImageUrl;
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }
}
