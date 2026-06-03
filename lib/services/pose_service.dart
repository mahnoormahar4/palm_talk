import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class PoseService {

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );

  final FaceMeshDetector _faceMeshDetector = FaceMeshDetector(
    option: FaceMeshDetectorOptions.faceMesh,
  );

  late HandLandmarkerPlugin _handLandmarker;
  bool _handLandmarkerReady = false;

  static const List<int> _faceIndices = [
    1, 10, 152, 234, 454, 33, 263, 61, 291, 13, 14
  ];

  Future<void> init() async {
    try {
      _handLandmarker = HandLandmarkerPlugin.create(
        numHands: 2,
        minHandDetectionConfidence: 0.5,
      );
      _handLandmarkerReady = true;
      debugPrint('HandLandmarker initialised');
    } catch (e) {
      debugPrint('HandLandmarker init failed: $e');
    }
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription camera) {
    InputImageRotation rotation;
    switch (camera.sensorOrientation) {
      case 90:  rotation = InputImageRotation.rotation90deg;  break;
      case 180: rotation = InputImageRotation.rotation180deg; break;
      case 270: rotation = InputImageRotation.rotation270deg; break;
      default:  rotation = InputImageRotation.rotation0deg;
    }
    final bytes = image.planes[0].bytes;

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
  }

  Future<List<double>?> processFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (image.planes.isEmpty) return null;

    final inputImage = _toInputImage(image, camera);
    if (inputImage == null) return null;

    final results = await Future.wait([
      _poseDetector.processImage(inputImage),
      _faceMeshDetector.processImage(inputImage),
    ]);

    final poses      = results[0] as List<Pose>;
    final faceMeshes = results[1] as List<FaceMesh>;

    if (poses.isEmpty) return null;
    final pose = poses.first;

    List<Hand>? hands;
    if (_handLandmarkerReady) {
      try {
        hands = _handLandmarker.detect(image, camera.sensorOrientation);
      } catch (e) {
        debugPrint('Hand detection error: $e');
      }
    }

    return _buildFeatureVector(
      pose,
      faceMeshes.isNotEmpty ? faceMeshes.first : null,
      hands,
    );
  }

  List<double> _buildFeatureVector(
    Pose pose,
    FaceMesh? faceMesh,
    List<Hand>? hands,
  ) {
    final features = List<double>.filled(177, 0.0);
    int offset = 0;

    Hand? rightHand;
    Hand? leftHand;
    if (hands != null) {
      if (hands.isNotEmpty) rightHand = hands[0];
      if (hands.length > 1) leftHand  = hands[1];
    }

    // [0..62] Right hand
    if (rightHand != null && rightHand.landmarks.length == 21) {
      for (final lm in rightHand.landmarks) {
        features[offset++] = lm.x;
        features[offset++] = lm.y;
        features[offset++] = lm.z;
      }
    } else {
      offset += 63;
    }

    // [63..125] Left hand
    if (leftHand != null && leftHand.landmarks.length == 21) {
      for (final lm in leftHand.landmarks) {
        features[offset++] = lm.x;
        features[offset++] = lm.y;
        features[offset++] = lm.z;
      }
    } else {
      offset += 63;
    }

    // [126..143] Pose
    final poseTypes = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    ];
    for (final type in poseTypes) {
      final lm = pose.landmarks[type];
      if (lm != null) {
        features[offset++] = lm.x;
        features[offset++] = lm.y;
        features[offset++] = lm.z;
      } else {
        offset += 3;
      }
    }

    // [144..176] Face
    if (faceMesh != null) {
      for (final idx in _faceIndices) {
        if (idx < faceMesh.points.length) {
          final pt = faceMesh.points[idx];
          features[offset++] = pt.x;
          features[offset++] = pt.y;
          features[offset++] = pt.z;
        } else {
          offset += 3;
        }
      }
    }

    return _normalise(features);
  }

  List<double> _normalise(List<double> f) {
    final out = List<double>.from(f);
    const int poseStart = 126;
    final lSx = f[poseStart],     lSy = f[poseStart + 1], lSz = f[poseStart + 2];
    final rSx = f[poseStart + 3], rSy = f[poseStart + 4], rSz = f[poseStart + 5];

    if (lSx == 0 && lSy == 0 && rSx == 0 && rSy == 0) return out;

    final midX = (lSx + rSx) / 2;
    final midY = (lSy + rSy) / 2;
    final midZ = (lSz + rSz) / 2;

    final dX = lSx - rSx;
    final dY = lSy - rSy;
    double shoulderWidth = sqrt(dX * dX + dY * dY);
    if (shoulderWidth < 1e-6) shoulderWidth = 1.0;

    for (int j = 0; j < 177; j += 3) {
      if (out[j] != 0 || out[j + 1] != 0) {
        out[j]     = (out[j]     - midX) / shoulderWidth;
        out[j + 1] = (out[j + 1] - midY) / shoulderWidth;
        out[j + 2] = (out[j + 2] - midZ) / shoulderWidth;
      }
    }
    return out;
  }

  void close() {
    _poseDetector.close();
    _faceMeshDetector.close();
    if (_handLandmarkerReady) _handLandmarker.dispose();
  }
}
