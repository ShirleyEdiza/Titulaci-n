import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> solicitarPermiso() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String?> iniciarGrabacion() async {
    final tienePermiso = await solicitarPermiso();

    if (!tienePermiso) {
      return null;
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    return path;
  }

  Future<String?> detenerGrabacion() async {
    final path = await _recorder.stop();
    return path;
  }

  Future<bool> estaGrabando() async {
    return await _recorder.isRecording();
  }

  Future<void> eliminarAudio(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
