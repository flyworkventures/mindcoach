//import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/Controllers/all_controllers.dart';
import 'package:mindcoach/core/utils/screen_size_extensions.dart';

class VideoCallView extends   ConsumerStatefulWidget {
  const VideoCallView({super.key});

  @override
  ConsumerState<VideoCallView> createState() => _VideoCallViewState();
}

class _VideoCallViewState extends ConsumerState<VideoCallView> {
  @override
  void initState() {
    super.initState();
    // Initialize kamera
 //   Future.microtask(() => ref.read(AllControllers.videoCallController.notifier).initialize());
  }
  
  @override
  void dispose() {
    // Widget dispose olduğunda kamera ve image stream'i temizle
    //ref.read(AllControllers.videoCallController.notifier).cleanup();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(AllControllers.videoCallController);
    final cameraController = videoState.cameraController;
    
    // Debug log - her build'de çalışır
    if (cameraController != null) {
      debugPrint('📹 [VIDEO-CALL-VIEW] Build - Camera: isInitialized=${cameraController.value.isInitialized}, hasError=${cameraController.value.hasError}, errorDescription=${cameraController.value.errorDescription}');
    } else {
      debugPrint('📹 [VIDEO-CALL-VIEW] Build - Camera controller is null');
    }
    
    return Placeholder();
    
    
    /* Scaffold(
      body: Stack(
        children: [
          // Kamera preview - sadece initialize edilmiş ve hazır olduğunda göster
          if (cameraController != null && cameraController.value.isInitialized)

   
          Positioned(
            bottom: 20.h,
            right: 10.w,
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(20),
              child: SizedBox(
                width:150.w,
                height: 200.h,
                child: CameraPreview(cameraController))),
          )
              
            
          else if (cameraController != null && cameraController.value.hasError)
            // Hata durumu
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Kamera hatası: ${cameraController.value.errorDescription ?? "Bilinmeyen hata"}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            // Loading
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    cameraController == null 
                        ? 'Kamera başlatılıyor...' 
                        : 'Kamera hazırlanıyor...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    */
  }
}