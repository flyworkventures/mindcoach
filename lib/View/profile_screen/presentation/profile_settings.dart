import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindcoach/Riverpod/providers/all_providers.dart';
import 'dart:io';
import 'dart:convert';

import '../../../core/routes/page_routes.dart';
import '../../../core/utils/context_l10n_extensions.dart';
import '../../../core/utils/screen_size_extensions.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/locale/locale_provider.dart';

import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_title.dart';
import '../../../core/widgets/app_scaffold_background.dart';
import '../../../core/widgets/pill_dropdown.dart';
import '../../../core/widgets/pill_text_field.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/controller/auth_controller.dart';
import '../../../Riverpod/providers/user_provider.dart';
import '../../../core/utils/app_constants.dart';
import '../../../Http/http_service.dart';
import '../../../models/user_model.dart';
import '../../../core/config/app_status_notifier.dart';
import 'package:http/http.dart' as http;

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String? _selectedLanguageCode;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();

    // Mevcut userProvider'dan kullanıcı bilgilerini al
    final user = ref.read(AllProviders.userProvider);
    if (user != null) {
      // Username'i fullName olarak kullan
      _nameController = TextEditingController(text: user.username ?? '');
      
      // Email'i credentialData'dan al
      String email = '';
      if (user.credentialData != null && user.credentialData is Map) {
        final credentialData = user.credentialData as Map;
        email = credentialData['email']?.toString() ?? '';
      }
      _emailController = TextEditingController(text: email);
      
      // Phone şimdilik boş (API'de phone field'ı yok)
      _phoneController = TextEditingController(text: '');
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = ref.read(localeProvider);
      final systemLocaleCode = context.langCode;
      final initialCode = currentLocale?.languageCode ?? systemLocaleCode;

      if (!mounted) return;
      setState(() {
        _selectedLanguageCode = initialCode;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Fotoğraf seç ve yükle
  Future<void> _pickAndUploadPhoto() async {
    try {
      // Fotoğraf seçme seçenekleri göster
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kameradan Çek'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Fotoğraf seç
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      // Fotoğrafı backend'e yükle
      await _uploadPhoto(File(image.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil fotoğrafı güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  /// Fotoğrafı backend'e yükle
  Future<void> _uploadPhoto(File photoFile) async {
    try {
      final url = Uri.parse("${AppConstants.baseURL}/auth/profile/photo");
      
      // Multipart request oluştur
      final request = http.MultipartRequest('POST', url);
      
      // Authorization header ekle
      final token = ref.read(AllProviders.userProvider)?.token ?? "";
      request.headers['Authorization'] = 'Bearer $token';
      
      // Fotoğraf dosyasını ekle
      request.files.add(
        await http.MultipartFile.fromPath('photo', photoFile.path),
      );
      
      // İsteği gönder
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          // UserModel'i güncelle
          final userModel = UserModel.fromMap(json['data']['user']);
          // Token'ı koru
          final currentUser = ref.read(AllProviders.userProvider);
          final updatedUser = userModel.copyWith(
            token: currentUser?.token,
          );
          ref.read(AllProviders.userProvider.notifier).setUserModel(updatedUser);
        }
      } else {
        final json = jsonDecode(response.body);
        throw Exception(json['error'] ?? 'Fotoğraf yüklenemedi');
      }
    } catch (e) {
      throw Exception('Fotoğraf yükleme hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isSmallHeight = media.size.height < 700;
    final l10n = context.l10n;

    final supportedLanguages = {
      'en': l10n.english,
      'tr': l10n.turkish,
      'de': l10n.german,
    };

    return Scaffold(
      body: AppScaffoldBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // TOP BAR
                      Row(
                        children: const [
                          AppBackButton(),
                          Spacer(),
                          AppTitle(gradient: true),
                          Spacer(),
                          SizedBox(width: 34),
                        ],
                      ),

                      SizedBox(height: isSmallHeight ? 16 : 24),

                      // AVATAR + EDIT
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Builder(
                              builder: (context) {
                                final user = ref.watch(AllProviders.userProvider);
                                final imageProvider = user?.profilePhotoUrl != null && user!.profilePhotoUrl!.isNotEmpty
                                    ? NetworkImage(user.profilePhotoUrl!) as ImageProvider
                                    :  NetworkImage(AppConstants.defaultPpUrl) as ImageProvider;
                                
                                return Container(
                                  width: 142,
                                  height: 142,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                                child: Container(
                                  width: 42.93,
                                  height: 42.93,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: _isUploadingPhoto
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                AppColors.primaryGreen,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: SvgPicture.asset(
                                            'assets/svg/edit.svg',
                                            width: 20,
                                            height: 20,
                                            colorFilter: const ColorFilter.mode(
                                              AppColors.primaryGreen,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallHeight ? 24 : 32),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            PillTextField(
                              label: l10n.fullName,
                              controller: _nameController,
                              hintText: 'John Doe',
                            ),
                            const SizedBox(height: 16),
                            PillTextField(
                              label: 'E-mail',
                              controller: _emailController,
                              hintText: 'john@gmail.com',
                              readOnly: true,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
         

                            PillDropdown(
                              label: l10n.language,
                              value: _selectedLanguageCode,
                              items: supportedLanguages.entries.map((entry) {
                                return DropdownMenuItem<String>(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF525252),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newCode) {
                                if (newCode == null) return;

                                setState(() => _selectedLanguageCode = newCode);

                                final isSystemLocale = (newCode == context.langCode);
                                final Locale? localeToSet =
                                isSystemLocale ? null : Locale(newCode);

                                ref.read(localeProvider.notifier).setLocale(localeToSet);
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallHeight ? 24 : 32),

                      // SAVE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Profil güncelleme API'sine istek gönder
                              try {
                                final httpService = HttpService(ref: ref as dynamic);
                                final body = {
                                  'username': _nameController.text.trim(),
                                };
                                
                                final response = await httpService.put(
                                  path: AppConstants.completeProfileURL,
                                  body: body,
                                );
                                
                                if (response.statusCode == 200) {
                                  final json = jsonDecode(response.body);
                                  if (json['success'] == true && json['data'] != null) {
                                    // UserModel'i güncelle
                                    final userModel = UserModel.fromMap(json['data']['user']);
                                    // Token'ı koru
                                    final currentUser = ref.read(AllProviders.userProvider);
                                    final updatedUser = userModel.copyWith(
                                      token: currentUser?.token,
                                    );
                                    ref.read(AllProviders.userProvider.notifier).setUserModel(updatedUser);
                                    
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(l10n.save),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Güncelleme başarısız'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Hata: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                gradient: AppGradients.brandButton,
                              ),
                              child: Container(
                                height: 50.h,
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/svg/save.svg',
                                      width: 22,
                                      height: 22,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.save,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // LOGOUT + DELETE
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _OutlineActionButton(
                                title: l10n.logout,
                                iconAsset: 'assets/svg/logout.svg',
                                onTap: () {
                                  showConfirmDialog(
                                    context: context,
                                    title: l10n.logout,
                                    message: l10n.areYouSureLogout,
                                    confirmText: l10n.logout,
                                    confirmColor: const Color(0xFFFF3B3B),
                                    onConfirm: () async {
                                      // Logout işlemi
                                      final authState = ref.read(authControllerProvider);
                                      if (authState.isLoading) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Logout işlemi devam ediyor...'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                        }
                                        return;
                                      }
                                      
                                      // Loading göster
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Çıkış yapılıyor...'),
                                            backgroundColor: Colors.blue,
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                      
                                      try {
                                        await ref.read(AllProviders.authProvider.notifier).logout();
                                        // Logout başarılı, direkt Onboarding'e yönlendirildi
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Başarıyla çıkış yapıldı'),
                                              backgroundColor: Colors.green,
                                              duration: Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        // Hata durumunda kullanıcıya bilgi ver
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Logout hatası: $e'),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                        // Hata olsa bile AppStatus'u onboarding yap
                                        ref.read(appStatusProvider.notifier).goToOnboarding();
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _OutlineActionButton(
                                title: l10n.deleteAccount,
                                iconAsset: 'assets/svg/delete.svg',
                                onTap: () {
                                  showConfirmDialog(
                                    context: context,
                                    title: l10n.deleteProfile,
                                    message: l10n.areYouSureDelete,
                                    confirmText: l10n.delete,
                                    confirmColor: const Color(0xFFFF3B3B),
                                    onConfirm: () async {
                                      // Delete account işlemi
                                      final authState = ref.read(authControllerProvider);
                                      if (authState.isLoading) return;
                                      
                                      try {
                                        await ref.read(authControllerProvider.notifier).deleteAccount();
                                        // Delete account başarılı, AppStatus zaten unauthenticated yapıldı
                                        // Goodbye ekranına yönlendir
                                        if (mounted) {
                                          Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            PageRoutes.goodbye,
                                            (route) => false,
                                          );
                                        }
                                      } catch (e) {
                                        // Hata durumunda kullanıcıya bilgi ver
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Hesap silme hatası: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(height: media.padding.bottom),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  final String title;
  final String iconAsset;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.title,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFB1B1B1), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          backgroundColor: Colors.white,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 25,
                height: 25,
                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
