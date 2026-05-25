import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/app_provider.dart';
import '../services/storage_service.dart';
import 'create_thread_screen.dart';
import 'recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,

        title: const Text(
          'Dataset Threads',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 24,
          ),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.shade50,
              child: Icon(
                Icons.dataset_rounded,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),

      body: Consumer<AppProvider>(
        builder: (context, provider, child) {

          // =========================
          // EMPTY STATE
          // =========================

          if (provider.threads.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Container(
                      padding: const EdgeInsets.all(30),

                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        Icons.folder_open_rounded,
                        size: 90,
                        color: Colors.blue.shade700,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      "No Dataset Threads Yet",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Create a new dataset thread to start recording and organizing your audio samples professionally.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 3,
                      ),

                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CreateThreadScreen(),
                          ),
                        );
                      },

                      icon: const Icon(Icons.add),

                      label: const Text(
                        "Create New Thread",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // =========================
          // THREAD LIST
          // =========================

          return Column(
            children: [

              // TOP HEADER CARD

              Container(
                margin: const EdgeInsets.all(18),
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade700,
                      Colors.indigo.shade600,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(24),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),

                child: Row(
                  children: [

                    Container(
                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          const Text(
                            "Voice Dataset Manager",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "${provider.threads.length} Threads Available",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // LIST

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 18,
                    right: 18,
                    bottom: 120,
                  ),

                  itemCount: provider.threads.length,

                  itemBuilder: (context, index) {
                    final dir = provider.threads[index];

                    final folderName =
                        dir.path.split('/').last;

                    final fileCount =
                        Directory(dir.path)
                            .listSync()
                            .whereType<File>()
                            .length;

                    return Container(
                      margin:
                          const EdgeInsets.only(bottom: 18),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(24),

                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),

                      child: Material(
                        color: Colors.transparent,

                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(24),

                          onTap: () {
                            provider.resetIndex();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RecordingScreen(
                                  threadDir: dir,
                                ),
                              ),
                            );
                          },

                          child: Padding(
                            padding:
                                const EdgeInsets.all(20),

                            child: Row(
                              children: [

                                // ICON

                                Container(
                                  padding:
                                      const EdgeInsets.all(16),

                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade400,
                                        Colors.deepOrange.shade400,
                                      ],
                                    ),

                                    borderRadius:
                                        BorderRadius.circular(
                                      18,
                                    ),
                                  ),

                                  child: const Icon(
                                    Icons.folder_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),

                                const SizedBox(width: 18),

                                // TEXT

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,

                                    children: [

                                      Text(
                                        folderName,

                                        
                                        style:
                                            const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.bold,
                                          color:
                                              Colors.black87,
                                        ),
                                      ),

                                      const SizedBox(
                                          height: 8),

                                      Row(
                                        children: [

                                          Icon(
                                            Icons.audio_file,
                                            size: 16,
                                            color:
                                                Colors.grey
                                                    .shade600,
                                          ),

                                          const SizedBox(
                                              width: 6),

                                          Text(
                                            "$fileCount files",
                                            style:
                                                TextStyle(
                                              color: Colors
                                                  .grey
                                                  .shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // SHARE BUTTON

                                Container(
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.blue.shade50,
                                    borderRadius:
                                        BorderRadius
                                            .circular(14),
                                  ),

                                  child: IconButton(
                                    icon: Icon(
                                      Icons.share_rounded,
                                      color: Colors
                                          .blue.shade700,
                                    ),

                                    onPressed: () async {
                                      ScaffoldMessenger.of(
                                              context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Preparing ZIP file...',
                                          ),
                                        ),
                                      );

                                      try {
                                        String zipPath =
                                            await StorageService
                                                .zipThread(
                                                    dir);

                                        await Share
                                            .shareXFiles(
                                          [
                                            XFile(
                                              zipPath,
                                              mimeType:
                                                  'application/zip',
                                            ),
                                          ],

                                          subject:
                                              'Dataset Backup: $folderName',
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                                context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString(),
                                            ),

                                            backgroundColor:
                                                Colors.red,

                                            duration:
                                                const Duration(
                                              seconds: 6,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // =========================
      // FAB
      // =========================

      floatingActionButton:
          FloatingActionButton.extended(
        elevation: 6,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const CreateThreadScreen(),
            ),
          );
        },

        icon: const Icon(Icons.add),

        label: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'New Thread',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}