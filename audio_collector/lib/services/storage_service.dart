import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

class StorageService {
  static Future<Directory> getBaseDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${directory.path}/SpeechDatasets');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
  }

  static Future<Directory> createThread(String region, String gender, String name) async {
    final baseDir = await getBaseDirectory();
    final dirs = baseDir.listSync().whereType<Directory>().toList();
    
    int newId = dirs.length + 1;
    String idString = newId.toString().padLeft(3, '0');
    String folderName = '${region}_speaker_${gender}_${idString}_$name'.toLowerCase();
    
    final threadDir = Directory('${baseDir.path}/$folderName');
    await threadDir.create();
    return threadDir;
  }

  static Future<List<Directory>> getAllThreads() async {
    final baseDir = await getBaseDirectory();
    return baseDir.listSync().whereType<Directory>().toList();
  }
  static Future<String> zipThread(Directory threadDir) async {
    final tempDir = await getTemporaryDirectory();
    String folderName = threadDir.path.split('/').last;
    String zipPath = '${tempDir.path}/$folderName.zip';
    
    final existingZip = File(zipPath);
    if (existingZip.existsSync()) existingZip.deleteSync();

    // Give Android half a second to release file locks
    await Future.delayed(const Duration(milliseconds: 500));

    List<FileSystemEntity> contents = threadDir.listSync();
    
    // THE FIX: Use the core Archive class instead of the ZipFileEncoder wrapper
    Archive archive = Archive();
    int validAudioCount = 0;

    for (var entity in contents) {
      if (entity is File && entity.path.endsWith('.wav')) {
        int size = entity.lengthSync();
        if (size > 0) {
          String fileName = entity.path.split('/').last;
          
          // 1. Read the audio bytes directly from the hard drive
          List<int> bytes = entity.readAsBytesSync();
          
          // 2. Add those raw bytes to our in-memory archive
          archive.addFile(ArchiveFile(fileName, bytes.length, bytes));
          validAudioCount++;
        }
      }
    }

    if (validAudioCount == 0) {
      throw Exception("No valid WAV files found in the folder.");
    }

    // 3. Encode the entire archive into the ZIP format in memory
    ZipEncoder encoder = ZipEncoder();
    List<int>? zipData = encoder.encode(archive);

    if (zipData == null || zipData.isEmpty) {
      throw Exception("Flutter failed to compress the audio bytes.");
    }

    // 4. Write the massive chunk of zipped bytes to the final file
    File(zipPath).writeAsBytesSync(zipData);

    // 5. Final sanity check
    final finalZip = File(zipPath);
    int finalSize = finalZip.lengthSync();
    
    if (finalSize < 100) {
      throw Exception("ZIP CORRUPTED. Final size is only $finalSize bytes.");
    }

    return zipPath;
  }
  static String getExpectedAudioPath(Directory threadDir, int sentenceIndex) {
    String fileId = (sentenceIndex + 1).toString().padLeft(3, '0');
    return '${threadDir.path}/sound_$fileId.wav';
  }
}