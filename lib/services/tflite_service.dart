import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {

  Interpreter? _interpreter;

  // ================= LABEL MAP =================

  final List<String> labels = [
    "call",
    "come",
    "drink",
    "eat",
    "fast",
    "give",
    "go",
    "goodbye",
    "hello",
    "help",
    "home",
    "hospital",
    "i",
    "money",
    "need",
    "ok",
    "police",
    "school",
    "sick",
    "sorry",
    "take",
    "thanks",
    "tired",
    "what",
    "you",
  ];

  // ================= LOAD MODEL =================

  Future<void> loadModel() async {
    try {
      print("🚀 STARTING MODEL LOAD");

      // FIXED: tflite_flutter 0.10.x uses InterpreterOptions instead of
      // passing options directly. resizeInputTensor must be called after
      // fromAsset but before allocateTensors.
      final options = InterpreterOptions()..threads = 2;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/psl_model.tflite',
        options: options,
      );

      // Resize input to match the model's expected shape [1, 30, 177]
      _interpreter!.resizeInputTensor(0, [1, 30, 177]);
      _interpreter!.allocateTensors();

      print("✅ Model loaded");
      print("INPUT : ${_interpreter!.getInputTensor(0).shape}");
      print("OUTPUT: ${_interpreter!.getOutputTensor(0).shape}");

    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  // ================= RUN MODEL =================

  Future<String> runModel(
      List<List<double>> sequence,
      ) async {

    try {

      if (_interpreter == null) {
        return "Model Not Loaded";
      }

      debugPrint("🚀 RUNNING MODEL");

      // =====================================================
      // INPUT SHAPE: [1, 30, 177]
      // sequence is List<List<double>> of shape [30, 177]
      // wrap in outer list to get [1, 30, 177]
      // =====================================================

      // FIXED: tflite_flutter 0.10.x requires typed nested lists.
      // Convert to List<List<List<double>>> with shape [1, 30, 177].
      final input = [sequence]; // shape: [1, 30, 177]

      // =====================================================
      // OUTPUT SHAPE: [1, 25]
      // =====================================================

      final output = List.generate(
        1,
            (_) => List.filled(labels.length, 0.0),
      );

      debugPrint("INPUT READY");

      _interpreter!.run(input, output);

      debugPrint("MODEL EXECUTED");

      final scores = output[0];

      // =====================================================
      // FIND BEST PREDICTION
      // =====================================================

      double maxScore = scores[0];
      int maxIndex = 0;

      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIndex = i;
        }
      }

      debugPrint("Prediction: ${labels[maxIndex]}");
      debugPrint("Confidence: $maxScore");

      // =====================================================
      // CONFIDENCE CHECK
      // =====================================================

      if (maxScore < 0.70) {
        return "Unknown";
      }

      return labels[maxIndex];

    } catch (e) {

      debugPrint("❌ Inference Error: $e");
      return "Error";
    }
  }

  // ================= CLOSE =================

  void close() {
    _interpreter?.close();
  }
}
