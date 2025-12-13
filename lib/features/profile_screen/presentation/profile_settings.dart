import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
import '../notifiers/user_notifier.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();

    final user = ref.read(userProvider);
    _nameController = TextEditingController(text: user.fullName);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone);

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
                            Container(
                              width: 142,
                              height: 142,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(ref.watch(userProvider).avatarAssetPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
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
                                child: Center(
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
                            PillTextField(
                              label: l10n.phoneNumber,
                              controller: _phoneController,
                              hintText: '+90 5xx xxx xx xx',
                              keyboardType: TextInputType.phone,
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
                            onPressed: () {
                              ref.read(userProvider.notifier).updateUser(
                                fullName: _nameController.text,
                                phone: _phoneController.text,
                              );
                              // İstersen burada toast/snackbar ekleriz
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
                                    onConfirm: () {
                                      // TODO: auth logout
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
                                    onConfirm: () {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        PageRoutes.goodbye,
                                            (route) => false,
                                      );
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
