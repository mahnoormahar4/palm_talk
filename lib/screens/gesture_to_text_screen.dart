import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'language_selection_screen.dart';
import '../services/tflite_service.dart';
import '../services/pose_service.dart';

class GestureToTextVoiceScreen extends StatefulWidget {
  const GestureToTextVoiceScreen({super.key});

  @override
  State<GestureToTextVoiceScreen> createState() =>
      _GestureToTextVoiceScreenState();
}

class _GestureToTextVoiceScreenState extends State<GestureToTextVoiceScreen> {

  // =========================================================
  // STATE
  // =========================================================

  List<String> detectedWords        = [];
  bool          isSentenceCompleted = false;
  bool          isRecording         = false;   // true while collecting frames
  bool          isProcessing        = false;   // true while running inference
  bool          isCameraInitialized = false;
  bool          _isProcessingFrame  = false;
  String        currentPrediction   = "";
  String        statusMessage       = "Press Record to start";

  String get fullSentence => detectedWords.join(" ");

  // =========================================================
  // SERVICES
  // =========================================================

  late FlutterTts        tts;
  final TFLiteService    tfliteService = TFLiteService();
  final PoseService      poseService   = PoseService();

  // =========================================================
  // CAMERA
  // =========================================================

  CameraController?      controller;
  CameraDescription?     _frontCamera;

  // =========================================================
  // LANDMARK BUFFER
  //
  // We collect frames until we have 30 valid landmark vectors,
  // then feed them as a sequence to the model.
  // =========================================================

  static const int _requiredFrames = 30;
  final List<List<double>> _frameBuffer = [];

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    _initTTS();
    _initCamera();
    _loadModel();
    poseService.init();
  }

  Future<void> _loadModel() async {
    try {
      await tfliteService.loadModel();
      debugPrint("✅ TFLite model loaded.");
    } catch (e) {
      debugPrint("❌ Model load error: $e");
    }
  }

  void _initTTS() {
    tts = FlutterTts();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      _frontCamera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        _frontCamera!,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,  // required for ML Kit
      );

      await controller!.initialize();

      if (!mounted) return;

      setState(() {
        isCameraInitialized = true;
      });

    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  // =========================================================
  // RECORD GESTURE
  //
  // Streams camera frames through ML Kit Pose Detection,
  // collects 30 valid landmark vectors, then runs inference.
  // =========================================================

  Future<void> startRecording() async {
    if (isRecording || isProcessing || isSentenceCompleted) return;
    if (controller == null || !controller!.value.isInitialized) return;

    _frameBuffer.clear();

    setState(() {
      isRecording      = true;
      currentPrediction = "";
      statusMessage    = "Recording... (0 / $_requiredFrames frames)";
    });

    // Start image stream
    await controller!.startImageStream((CameraImage image) async {
      if (!isRecording) return;               // stop if cancelled
      if (_frameBuffer.length >= _requiredFrames) return;  // buffer full

      if (_isProcessingFrame) return;
        _isProcessingFrame = true;
        try {
          final features = await poseService.processFrame(
          image,
          _frontCamera!,
        );

        debugPrint("Frame result: " + (features != null ? features.length.toString() : "null"));
        if (features != null) {
          _frameBuffer.add(features);

          if (mounted) {
            setState(() {
              statusMessage =
              "Recording... (${_frameBuffer.length} / $_requiredFrames frames)";
            });
          }

          // Once we have enough frames, stop the stream and run inference
          if (_frameBuffer.length >= _requiredFrames) {
            await controller!.stopImageStream();
            await _runInference();
          }
        }
      } catch (e) {
          debugPrint("Frame processing error: $e");
        } finally {
          _isProcessingFrame = false;
        }
    });
  }

  // =========================================================
  // STOP RECORDING (manual cancel)
  // =========================================================

  Future<void> stopRecording() async {
    if (!isRecording) return;

    try {
      await controller!.stopImageStream();
    } catch (_) {}

    setState(() {
      isRecording   = false;
      statusMessage = "Cancelled. Press Record to try again.";
    });
  }

  // =========================================================
  // RUN INFERENCE
  // =========================================================

  Future<void> _runInference() async {
    setState(() {
      isRecording   = false;
      isProcessing  = true;
      statusMessage = "Analysing gesture...";
    });

    try {
      final prediction = await tfliteService.runModel(_frameBuffer);

      if (mounted) {
        setState(() {
          currentPrediction = prediction;
          isProcessing      = false;
          statusMessage     = prediction == "Unknown"
              ? "Gesture not recognised. Try again."
              : "Detected: $prediction";

          // Add to sentence only if confident and not duplicate
          if (prediction != "Unknown" && prediction != "Error") {
            if (detectedWords.isEmpty || detectedWords.last != prediction) {
              detectedWords.add(prediction);
            }
          }
        });
      }
    } catch (e) {
      debugPrint("Inference error: $e");
      if (mounted) {
        setState(() {
          isProcessing  = false;
          statusMessage = "Error during inference.";
        });
      }
    }
  }

  // =========================================================
  // SENTENCE CONTROLS
  // =========================================================

  void completeSentence() {
    setState(() {
      isSentenceCompleted = true;
      statusMessage       = "Sentence completed ✔";
    });
  }

  void resetSentence() {
    setState(() {
      detectedWords       = [];
      currentPrediction   = "";
      isSentenceCompleted = false;
      statusMessage       = "Press Record to start";
    });
  }

  void onQuickGesture(String text) {
    if (isSentenceCompleted) return;
    setState(() {
      detectedWords.add(text);
    });
  }

  Future<void> speakText() async {
    if (fullSentence.isEmpty) return;
    await tts.speak(fullSentence);
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    try { controller?.stopImageStream(); } catch (_) {}
    controller?.dispose();
    tts.stop();
    tfliteService.close();
    poseService.close();
    super.dispose();
  }

  // =========================================================
  // CAMERA WIDGET
  // =========================================================

  Widget _buildCamera() {
    if (!isCameraInitialized || controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final size = controller!.value.previewSize;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width:  size != null ? size.height : 1,
            height: size != null ? size.width  : 1,
            child: CameraPreview(controller!),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("👋 Gesture → Text"),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetSentence,
          ),
        ],
      ),

      body: Column(
        children: [

          // ─────────────────────────────────────────────────
          // CAMERA BOX
          // ─────────────────────────────────────────────────

          Container(
            height: 320,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [

                _buildCamera(),

                // Loading overlay during inference
                if (isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),

                // Recording indicator
                if (isRecording)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record,
                              color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text("REC",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                // Current prediction label
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentPrediction.isEmpty
                          ? "No Prediction"
                          : currentPrediction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Status message
                Positioned(
                  bottom: 60,
                  left: 12,
                  right: 12,
                  child: Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ),

                // Buttons
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [

                        // RECORD button — starts collecting 30 frames
                        ElevatedButton.icon(
                          onPressed: (isProcessing || isSentenceCompleted)
                              ? null
                              : (isRecording ? stopRecording : startRecording),
                          icon: Icon(isRecording
                              ? Icons.stop
                              : Icons.fiber_manual_record),
                          label: Text(isRecording ? "Stop" : "Record"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            isRecording ? Colors.red : null,
                          ),
                        ),

                        // COMPLETE button
                        ElevatedButton(
                          onPressed: detectedWords.isEmpty
                              ? null
                              : completeSentence,
                          child: const Text("Complete"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─────────────────────────────────────────────────
          // SENTENCE BOX
          // ─────────────────────────────────────────────────

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text("📝 Sentence",
                    style: TextStyle(fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    fullSentence.isEmpty
                        ? "No gestures detected"
                        : fullSentence,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                if (isSentenceCompleted)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("Sentence completed ✔",
                        style: TextStyle(color: Colors.green)),
                  ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    // Translate button
                    IconButton(
                      icon: const Icon(Icons.translate),
                      onPressed: fullSentence.isEmpty
                          ? null
                          : () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LanguageSelectionScreen(
                              detectedText: fullSentence,
                            ),
                          ),
                        );
                        if (result != null) setState(() {});
                      },
                    ),

                    // Speak button
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: speakText,
                    ),

                    // Delete last word
                    IconButton(
                      icon: const Icon(Icons.backspace_outlined),
                      onPressed: (detectedWords.isEmpty || isSentenceCompleted)
                          ? null
                          : () => setState(() => detectedWords.removeLast()),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ─────────────────────────────────────────────────
          // QUICK GESTURES
          // ─────────────────────────────────────────────────

          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("⚡ Quick Gestures"),
            ),
          ),

          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _quickBtn("👋 Hello"),
                _quickBtn("👍 Good"),
                _quickBtn("✌️ Peace"),
                _quickBtn("💖 Love"),
                _quickBtn("🙏 Thanks"),
                _quickBtn("👏 Clap"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // QUICK BUTTON WIDGET
  // =========================================================

  Widget _quickBtn(String text) {
    final parts = text.split(" ");
    final emoji = parts.first;
    final label = parts.sublist(1).join(" ");

    return GestureDetector(
      onTap: () => onQuickGesture(text),
      child: Container(
        width: 90,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}