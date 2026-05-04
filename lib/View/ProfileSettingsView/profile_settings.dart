import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mindcoach/Riverpod/Controllers/all_controllers.dart';

import '../../Riverpod/Providers/all_providers.dart';
import '../../core/routes/page_routes.dart';
import '../../core/utils/app_constants.dart';
import '../../core/utils/revenuecat_paywalls.dart';
import '../../core/widgets/future_progress_dialog.dart';
import '../../core/utils/context_l10n_extensions.dart';
import '../../models/user_model.dart';
import '../auth/presentation/controller/auth_controller.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;

  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();

    final user = ref.read(AllProviders.userProvider);
    if (user != null) {
      _nameController = TextEditingController(text: user.username ?? '');
      _ageController = TextEditingController(
        text: user.age != null ? user.age.toString() : '',
      );

      String email = '';
      if (user.credentialData != null && user.credentialData is Map) {
        final credentialData = user.credentialData as Map;
        email = credentialData['email']?.toString() ?? '';
      }
      _emailController = TextEditingController(text: email);
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _ageController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.l10n.profileFromGallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(context.l10n.profileFromCamera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

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

      await _uploadPhoto(File(image.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profilePhotoUpdated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorGeneral), backgroundColor: Colors.red),
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

  Future<void> _uploadPhoto(File photoFile) async {
    try {
      final url = Uri.parse("${AppConstants.baseURL}/auth/profile/photo");
      final request = http.MultipartRequest('POST', url);
      final token = ref.read(AllProviders.userProvider)?.token ?? "";
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('photo', photoFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final userModel = UserModel.fromMap(json['data']['user']);
          final currentUser = ref.read(AllProviders.userProvider);
          final updatedUser = userModel.copyWith(token: currentUser?.token);
          ref
              .read(AllProviders.userProvider.notifier)
              .setUserModel(updatedUser);
        }
      } else {
        final json = jsonDecode(response.body);
        throw Exception(json['error'] ?? 'Fotoğraf yüklenemedi');
      }
    } catch (e) {
      throw Exception('Fotoğraf yükleme hatası: $e');
    }
  }

  // --- TEK BOTTOM SHEET FLOW ---
  void _showDeleteAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeleteAccountFlowSheet(
        onDeleteConfirmed: _deleteAccountWithFeedback,
      ),
    );
  }

  Future<bool> _deleteAccountWithFeedback(DeleteAccountFeedback feedback) async {
    final authState = ref.read(authControllerProvider);
    if (authState.isLoading) return false;

    try {
      await context.runWithProgressDialog(
        () => ref.read(authControllerProvider.notifier).deleteAccount(
              deleteReason: feedback.reason,
              deleteMessage: feedback.message,
            ),
        message: context.l10n.pleaseWait,
      );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorOperationFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isSmallHeight = media.size.height < 700;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. KISIM: KAYDIRILABİLİR FORM ALANI
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- TOP BAR ---
                    Row(
                      children: [
                        GestureDetector(
                          onTap: Navigator.of(context).pop,
                          child: SvgPicture.asset("assets/icons/ic_bakc.svg"),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.profileSettings,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallHeight ? 24 : 32),

                    // --- AVATAR ---
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Builder(
                            builder: (context) {
                              final userModel = ref.watch(
                                AllProviders.userProvider,
                              );
                              final ppPath = userModel?.profilePhotoUrl ?? '';

                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                  color: Colors.white,
                                  image: ppPath.isNotEmpty
                                      ? DecorationImage(
                                          image: CachedNetworkImageProvider(ppPath),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: ppPath.isEmpty
                                    ? SvgPicture.asset(
                                        'assets/icons/ic_mind_profile.svg',
                                      )
                                    : null,
                              );
                            },
                          ),
                          Positioned(
                            bottom: -5,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingPhoto
                                  ? null
                                  : _pickAndUploadPhoto,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                child: _isUploadingPhoto
                                    ? const Center(
                                        child: SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF21BC87),
                                                ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: SvgPicture.asset(
                                          "assets/icons/ic_cam.svg",
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallHeight ? 32 : 40),

                    // --- FORM ALANLARI ---
                    _ProfileTextField(
                      label: l10n.fullName,
                      hintText: l10n.enterYourFullName,
                      controller: _nameController,
                      prefixIcon: SvgPicture.asset(
                        "assets/icons/ic_settings_profile.svg",
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProfileTextField(
                      label: l10n.email,
                      hintText: l10n.emailHint,
                      controller: _emailController,
                      prefixIcon: SvgPicture.asset("assets/icons/ic_mail.svg"),
                      isReadOnly: true,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _ProfileTextField(
                      label: l10n.age,
                      hintText: l10n.enterYourAge,
                      controller: _ageController,
                      prefixIcon: SvgPicture.asset("assets/icons/ic_cake.svg"),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ),

            // 2. KISIM: EKRANIN EN ALTINA SABİTLENMİŞ BUTONLAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(
                              AllControllers.pageSettingsController.notifier,
                            )
                            .updateProfile(
                              name: _nameController.text.trim(),
                              age: _ageController.text.trim(),
                              successText: l10n.profileSaved,
                              errorText: l10n.errorGeneral,
                              context: context,
                            );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21BC87),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      icon: SvgPicture.asset("assets/icons/ic_save.svg"),
                      label: Text(
                        l10n.save,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        // İlk adımı (Bottomsheet'i) başlat
                        _showDeleteAccountSheet(context);
                      },
                      icon: SvgPicture.asset("assets/icons/ic_delete_acc.svg"),
                      label: Text(
                        l10n.deleteAccount,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF3F3F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeleteAccountFeedback {
  final String? reason;
  final String? message;

  const DeleteAccountFeedback({this.reason, this.message});
}

class _DeleteAccountFlowSheet extends StatefulWidget {
  final Future<bool> Function(DeleteAccountFeedback feedback) onDeleteConfirmed;

  const _DeleteAccountFlowSheet({required this.onDeleteConfirmed});

  @override
  State<_DeleteAccountFlowSheet> createState() => _DeleteAccountFlowSheetState();
}

class _DeleteAccountFlowSheetState extends State<_DeleteAccountFlowSheet> {
  int _step = 0;
  DeleteAccountFeedback _feedback = const DeleteAccountFeedback();

  void _goNext() => setState(() => _step = (_step + 1).clamp(0, 3));
  void _goBack() => setState(() => _step = (_step - 1).clamp(0, 3));

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 0:
        return _DeleteAccountBottomSheet(
          initialFeedback: _feedback,
          onNext: (feedback) {
            _feedback = feedback;
            _goNext();
          },
        );
      case 1:
        return _SpecialOfferBottomSheet(
          onBack: _goBack,
          onNext: _goNext,
          onSwitchToMonthlyPlan: () async {
            Navigator.of(context).pop();
            await Future.microtask(() {});
            await presentProOffersPaywall();
          },
        );
      case 2:
        return _FinalOfferBottomSheet(
          onBack: _goBack,
          onAcceptOffer: () async {
            Navigator.of(context).pop();
            await Future.microtask(() {});
            await presentDiscountPaywall();
          },
          onConfirmDelete: () async {
            final ok = await widget.onDeleteConfirmed(_feedback);
            if (!mounted || !ok) return;
            setState(() => _step = 3);
          },
        );
      default:
        return _CancelledBottomSheet(
          onReactivate: () => Navigator.of(context).pop(),
          onDone: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              PageRoutes.goodbye,
              (route) => false,
            );
          },
        );
    }
  }
}

// -----------------------------------------------------------------------------
// ADIM 1: DELETE ACCOUNT BOTTOM SHEET
// -----------------------------------------------------------------------------
class _DeleteAccountBottomSheet extends StatefulWidget {
  final ValueChanged<DeleteAccountFeedback> onNext;
  final DeleteAccountFeedback? initialFeedback;

  const _DeleteAccountBottomSheet({
    required this.onNext,
    this.initialFeedback,
  });

  @override
  State<_DeleteAccountBottomSheet> createState() =>
      _DeleteAccountBottomSheetState();
}

class _DeleteAccountBottomSheetState extends State<_DeleteAccountBottomSheet> {
  int? _selectedIndex;
  final TextEditingController _messageController = TextEditingController();
  bool _initializedFromFeedback = false;

  List<String> _getReasons(BuildContext context) {
    final l = context.l10n;
    return [
      l.deleteReasonNotRealistic,
      l.deleteReasonTechnicalIssues,
      l.deleteReasonPrice,
      l.deleteReasonNoCharacters,
      l.deleteReasonShortTry,
      l.deleteReasonOther,
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedFromFeedback) return;
    _initializedFromFeedback = true;
    final reasons = _getReasons(context);
    final initialReason = widget.initialFeedback?.reason;
    _selectedIndex = initialReason == null ? null : reasons.indexOf(initialReason);
    if (_selectedIndex == -1) _selectedIndex = null;
    _messageController.text = widget.initialFeedback?.message ?? '';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  width: 33,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF96989C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              color: Colors.black.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.deleteAccountWhyLeaving,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 18 / 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.deleteAccountImproveQuestion,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        height: 18 / 12,
                        color: Color(0xFF96989C),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(
                          _getReasons(context).length,
                          (index) => _buildRadioItem(index, _getReasons(context)[index]),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            context.l10n.messageOptionalLabel,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Container(
                            height: 51,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: TextField(
                              maxLines: 3,
                              minLines: 2,
                              controller: _messageController,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: context.l10n.messageOptionalHint,
                                hintStyle: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 10,
                            ),
                            backgroundColor: const Color(0xFF21BC87),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            context.l10n.cancel,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final reasons = _getReasons(context);
                            final selectedReason = (_selectedIndex != null &&
                                    _selectedIndex! >= 0 &&
                                    _selectedIndex! < reasons.length)
                                ? reasons[_selectedIndex!]
                                : null;
                            widget.onNext(
                              DeleteAccountFeedback(
                                reason: selectedReason,
                                message: _messageController.text.trim(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 10,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.black.withOpacity(0.10),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            context.l10n.next,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF96989C),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioItem(int index, String text) {
    bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF21BC87)
                          : const Color(0xFF96989C),
                      width: isSelected ? 5 : 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 14 / 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ADIM 2: SPECIAL OFFER BOTTOM SHEET
// -----------------------------------------------------------------------------
class _SpecialOfferBottomSheet extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Future<void> Function() onSwitchToMonthlyPlan;

  const _SpecialOfferBottomSheet({
    required this.onBack,
    required this.onNext,
    required this.onSwitchToMonthlyPlan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  width: 33,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF96989C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              color: Colors.black.withOpacity(0.05),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.specialOffer,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 18 / 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.specialOfferSubtitle,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF96989C),
                      height: 18 / 12,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SvgPicture.asset("assets/icons/ic_crown.svg"),
                                Positioned(
                                  bottom: -8,
                                  right: -2,
                                  child: SvgPicture.asset(
                                    "assets/icons/ic_warrantly_badge.svg",
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.switchTo1MonthPlan,
                                    style: const TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                      height: 20 / 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    context.l10n.monthlyPlanPrice,
                                    style: TextStyle(
                                      fontFamily: 'Geist',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black.withOpacity(0.5),
                                      letterSpacing: -0.6,
                                      height: 14 / 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.l10n.noLongTermCommitment,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            height: 20 / 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset("assets/icons/ic_keep.svg"),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.whatYouKeep,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 20 / 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem(context.l10n.featureAllCharacters),
                        const SizedBox(height: 12),
                        _buildFeatureItem(context.l10n.featureUnlimitedVideoCalls),
                        const SizedBox(height: 12),
                        _buildFeatureItem(context.l10n.featureUnlimitedCharacterEditing),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        await onSwitchToMonthlyPlan();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21BC87),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        context.l10n.switchToMonthlyPlan,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: onBack,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.black.withOpacity(0.10),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              context.l10n.back,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF96989C),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: onNext,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.black.withOpacity(0.10),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              context.l10n.next,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF96989C),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        SvgPicture.asset("assets/icons/ic_green_tick.svg"),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 22 / 13,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ADIM 3: FINAL OFFER BOTTOM SHEET
// -----------------------------------------------------------------------------
class _FinalOfferBottomSheet extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onConfirmDelete;
  final Future<void> Function() onAcceptOffer;

  const _FinalOfferBottomSheet({
    required this.onBack,
    required this.onConfirmDelete,
    required this.onAcceptOffer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  width: 33,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF96989C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              color: Colors.black.withOpacity(0.05),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.areYouSure,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 18 / 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.finalOfferSubtitle,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF96989C),
                      height: 18 / 12,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 18,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset("assets/icons/ic_keep.svg"),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.whatYouKeep,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 20 / 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPurpleFeatureItem(
                          'assets/icons/ic_char.svg',
                          context.l10n.featureUnlimitedCharacterAccess,
                        ),
                        const SizedBox(height: 12),
                        _buildPurpleFeatureItem(
                          'assets/icons/ic_video2.svg',
                          context.l10n.featureUnlimitedVideoCallAccess,
                        ),
                        const SizedBox(height: 12),
                        _buildPurpleFeatureItem(
                          'assets/icons/ic_char_edit.svg',
                          context.l10n.featureUnlimitedCharacterEditingAccess,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF21BC87),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              "assets/icons/ic_ticket.svg",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.stayAnd60Off,
                                style: const TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.1,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.bestOfferPrice,
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.1,
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        await onAcceptOffer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF21BC87),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        context.l10n.accept60OffAndStay,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: onBack,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.black.withOpacity(0.10),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              context.l10n.back,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF96989C),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: onConfirmDelete,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.black.withOpacity(0.10),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              context.l10n.next,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF96989C),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurpleFeatureItem(String iconPath, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE9D4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: SvgPicture.asset(iconPath)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 22 / 13,
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ADIM 4: CANCELLED (SAD TO SEE YOU GO) BOTTOM SHEET
// -----------------------------------------------------------------------------
class _CancelledBottomSheet extends StatelessWidget {
  final VoidCallback onDone;
  final VoidCallback onReactivate;

  const _CancelledBottomSheet({
    required this.onDone,
    required this.onReactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  width: 33,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF96989C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              color: Colors.black.withOpacity(0.05),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.sadToSeeYouGo,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 18 / 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.membershipCancelledInfo,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF96989C),
                      height: 18 / 12,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 20,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset("assets/icons/ic_keep.svg"),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.changeYourMind,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 20 / 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          context.l10n.reactivateInfo,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            height: 20 / 13,
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton(
                            onPressed: onReactivate,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.all(10),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SvgPicture.asset("assets/icons/ic_chain2.svg"),
                                const SizedBox(width: 8),
                                Text(
                                  context.l10n.waitReactivate,
                                  style: const TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: onDone,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        context.l10n.done,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF96989C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// YEREL WIDGET'LAR
// -----------------------------------------------------------------------------

class _ProfileTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final Widget prefixIcon;
  final bool isReadOnly;
  final TextInputType keyboardType;

  const _ProfileTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.prefixIcon,
    this.isReadOnly = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontFamily: 'Geist',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Color(0xFF96989C),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF96989C),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E2E2), width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              prefixIcon,
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: isReadOnly,
                  keyboardType: keyboardType,
                  style: textStyle,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: textStyle.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isReadOnly
                          ? const Color(0xFF96989C).withOpacity(0.5)
                          : const Color(0xFF96989C),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (isReadOnly) SvgPicture.asset("assets/icons/ic_lock2.svg"),
            ],
          ),
        ),
      ],
    );
  }
}



