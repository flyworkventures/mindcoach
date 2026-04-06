// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

//import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
//import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
//import 'package:permission_handler/permission_handler.dart';

import 'package:mindcoach/Utils/logger.dart';

class VideoController extends StateNotifier{
  Ref ref;
  VideoController(this.ref): super((null));
    /*
  FaceDetector faceDetector = FaceDetector(options: FaceDetectorOptions(
    enableClassification: true,
    enableLandmarks: true,
    enableTracking: true,
    performanceMode:  FaceDetectorMode.fast
  ));

  // Frame rate limiting için
  DateTime? _lastProcessedTime;
  static const Duration _minProcessingInterval = Duration(milliseconds: 200); // 5 FPS için face detection (60 FPS'den sadece her 12. frame'i işle)
  
  // İşlem devam ediyor mu kontrolü (concurrent processing önleme)
  bool _isProcessing = false;

  Future<void> initialize()async{
    requestPermission();
    CameraDescription?  cameras = await initializeCameras();
    initalizeCamera(cameras!);
    
  }




   void requestPermission()async{
  PermissionStatus requestStatus = await  Permission.camera.request();
  if (requestStatus.isGranted) {
    
  } else {
    
  }
   }

   Future<CameraDescription?> initializeCameras()async{
    try {
     List<CameraDescription> cameras =  await availableCameras();
     if (cameras.isEmpty) {
        Logger.errorLog(text: "Camera not found",className: "VideoController",functionName: "initializeCamera");
     }
   var fronCameraIndex = cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.front);

   if (fronCameraIndex == -1) {
     fronCameraIndex = 0;
   }

   return cameras[fronCameraIndex];
    } catch (e) {
      Logger.errorLog(text: "Camera not initalized: $e",className: "VideoController",functionName: "initializeCamera");
      return null;
    }




   }




 Future<void> initalizeCamera(CameraDescription camera)async{
  try {
    // 60 FPS için daha düşük resolution kullan (ultraHigh çok yüksek olabilir)
    // high veya veryHigh ile 60 FPS daha stabil çalışır
    final controller = CameraController(
      camera,
      ResolutionPreset.high, // ultraHigh yerine high kullan (60 FPS için daha uyumlu)
      enableAudio: false,
      fps: 60,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420
    );
    
    // Initialize işlemini await ile bekle ve hata yakala
    await controller.initialize();
    Logger.info(text: "Camera initialized successfully", className: "VideoController", functionName: "initalizeCamera");
    
    // Initialize başarılı olduktan sonra state'i güncelle (UI rebuild için)
    state = state.copyWith(cameraController: controller);
    Logger.info(text: "State updated with camera controller. isInitialized: ${controller.value.isInitialized}", className: "VideoController", functionName: "initalizeCamera");
    
    // Face detection'ı biraz geciktir (preview'ın render olması için)
    // NOT: startImageStream ve CameraPreview aynı anda kullanılabilir
    Future.delayed(const Duration(milliseconds: 500), () {
      startFacedetection();
    });
  } catch (e, stackTrace) {
    Logger.errorLog(text: "Camera initialization failed: $e", className: "VideoController", functionName: "initalizeCamera");
    Logger.errorLog(text: "Stack trace: $stackTrace", className: "VideoController", functionName: "initalizeCamera");
    
    // Hata durumunda state'i temizle
    state = state.copyWith(cameraController: null);
    
    // 60 FPS desteklenmiyorsa 30 FPS ile tekrar dene
    try {
      Logger.info(text: "Retrying with 30 FPS...", className: "VideoController", functionName: "initalizeCamera");
      final fallbackController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        fps: 30, // Fallback: 30 FPS
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420
      );
      
      state = state.copyWith(cameraController: fallbackController);
      await fallbackController.initialize();
      Logger.info(text: "Camera initialized with 30 FPS fallback", className: "VideoController", functionName: "initalizeCamera");
      startFacedetection();
    } catch (fallbackError) {
      Logger.errorLog(text: "Camera initialization failed even with 30 FPS: $fallbackError", className: "VideoController", functionName: "initalizeCamera");
      state = state.copyWith(cameraController: null);
    }
  }
 }


Future<void> startFacedetection()async{
  try {
    if (state.cameraController == null || !state.cameraController!.value.isInitialized) {
      Logger.errorLog(text: "Camera controller is null or not initialized", className: "VideoController", functionName: "startFacedetection");
      return;
    }
    
    Logger.info(text: "Face detection started with frame rate limiting (${_minProcessingInterval.inMilliseconds}ms interval)", className: "VideoController", functionName: "startFacedetection");
    
    // Image stream'i başlat - frame rate limiting ile
    state.cameraController!.startImageStream((CameraImage image) {
      // Frame rate limiting: Sadece belirli aralıklarla işle
      final now = DateTime.now();
      if (_lastProcessedTime != null && 
          now.difference(_lastProcessedTime!) < _minProcessingInterval) {
        // Bu frame'i atla - çok yakın zamanda işlem yapıldı
        return;
      }
      
      // Eğer önceki işlem hala devam ediyorsa, bu frame'i atla
      if (_isProcessing) {
        return;
      }
      
      // Bu frame'i işle
      _lastProcessedTime = now;
      _isProcessing = true;
      
      // Face detection'ı async olarak yap (UI thread'i bloklamamak için)
      _processFrameAsync(image).then((_) {
        _isProcessing = false;
      }).catchError((e) {
        Logger.errorLog(text: "Error in async frame processing: $e", className: "VideoController", functionName: "startFacedetection");
        _isProcessing = false;
      });
    });
    
    Logger.info(text: "Image stream started successfully", className: "VideoController", functionName: "startFacedetection");
  } catch (e, stackTrace) {
    Logger.errorLog(text: "Failed to start image stream: $e", className: "VideoController", functionName: "startFacedetection");
    Logger.errorLog(text: "Stack trace: $stackTrace", className: "VideoController", functionName: "startFacedetection");
  }
}

// Frame işleme - async olarak yapılır (UI thread'i bloklamaz)
Future<void> _processFrameAsync(CameraImage image) async {
  try {
    var inputImage = convertCameraImageToInputImage(image);
    if (inputImage != null) {
      // Face detection'ı await ile yap (ama UI thread'i bloklamaz çünkü bu async function)
      final faces = await faceDetector.processImage(inputImage);
      // Face detection sonuçlarını işle (gerekirse state'e kaydet)
      if (faces.isNotEmpty) {
        // Yüz tespit edildi - burada işlem yapılabilir
        // Örnek: state güncellemesi yapılabilir (ama dikkatli ol, çok sık yapma)
        
        log("Gümlme: ${faces.first.smilingProbability! *100}");
      }else{
        log("Yüz yok");
      }
    } else {
      Logger.errorLog(text: "Failed to convert camera image to input image", className: "VideoController", functionName: "_processFrameAsync");
    }
  } catch (e) {
    Logger.errorLog(text: "Error processing face detection: $e", className: "VideoController", functionName: "_processFrameAsync");
  }
}


InputImage? convertCameraImageToInputImage(CameraImage image){
  try {
    var format = Platform.isIOS ? InputImageFormat.bgra8888 : InputImageFormat.yuv420;
   final inputMetaData = InputImageMetadata(
    size: Size(image.width.toDouble(),image.height.toDouble()),
    rotation: InputImageRotation.values.firstWhere((e)=> e.rawValue == state.cameraController?.description.sensorOrientation),
    format: format,
    bytesPerRow: image.planes[0].bytesPerRow);
    final bytes = fromBytes(image.planes);
    return InputImage.fromBytes(bytes: bytes, metadata: inputMetaData);
  } catch (e) {
    return null;
  }

}

  Uint8List fromBytes(List<Plane> planes){
    final allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  // Dispose method - kamera ve image stream'i temizle
  // NOT: StateNotifier'ın dispose'u Riverpod tarafından otomatik çağrılır
  // Bu method manuel olarak çağrılabilir veya provider dispose olduğunda otomatik çağrılır
  Future<void> cleanup() async {
    try {
      if (state.cameraController != null) {
        // Image stream'i durdur
        if (state.cameraController!.value.isStreamingImages) {
          await state.cameraController!.stopImageStream();
          Logger.info(text: "Image stream stopped", className: "VideoController", functionName: "dispose");
        }
        
        // Kamera controller'ı dispose et
        await state.cameraController!.dispose();
        Logger.info(text: "Camera controller disposed", className: "VideoController", functionName: "dispose");
      }
      
      // Face detector'ı temizle
      await faceDetector.close();
      
      // State'i temizle
      state = VideoControllerViewModel(null);
      
      // Flag'leri sıfırla
      _isProcessing = false;
      _lastProcessedTime = null;
    } catch (e) {
      Logger.errorLog(text: "Error disposing VideoController: $e", className: "VideoController", functionName: "dispose");
    }
  }
*/
}
/*

class VideoControllerViewModel {
   CameraController? cameraController;

  VideoControllerViewModel(this.cameraController);

  VideoControllerViewModel copyWith({
    CameraController? cameraController,
  }) {
    return VideoControllerViewModel(
      cameraController ?? this.cameraController,
    );
  }

}
*/