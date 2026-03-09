import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/branding_service.dart';
import '../controllers/register_controller.dart';

/// Registration view with stepper form
///
/// Steps:
///   0: Personal info (name, email, password)
///   1: Gym info (gym name, main branch)
///   2: Optional branches
class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              // Content
              Expanded(
                child: Obx(() => _buildCurrentStep(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (controller.currentStep.value > 0) {
                controller.previousStep();
              } else {
                Get.back();
              }
            },
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                      _getStepSubtitle(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepSubtitle() {
    switch (controller.currentStep.value) {
      case 0:
        return 'Paso 1/3 · Datos personales';
      case 1:
        return 'Paso 2/3 · Tu gimnasio';
      case 2:
        return 'Paso 3/3 · Sucursales';
      default:
        return '';
    }
  }

  // =======================================
  // STEP INDICATOR
  // =======================================

  Widget _buildStepIndicator() {
    return Obx(() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          child: Row(
            children: List.generate(3, (index) {
              final isActive = index <= controller.currentStep.value;
              final isCurrent = index == controller.currentStep.value;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.blueAccent
                            : Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(color: Colors.blueAccent, width: 2)
                            : null,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (index < 2)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: index < controller.currentStep.value
                              ? Colors.blueAccent
                              : Colors.white.withOpacity(0.1),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ));
  }

  // =======================================
  // STEP ROUTER
  // =======================================

  Widget _buildCurrentStep(BuildContext context) {
    // Step 2 (gym branding) uses a special layout:
    // pinned preview at top, scrollable form below
    if (controller.currentStep.value == 1) {
      return _buildStep2Layout(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 8),
          Obx(() => controller.errorMessage.value != null
              ? _buildErrorMessage()
              : const SizedBox.shrink()),
          _buildStepContent(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Step 2 special layout: pinned preview + scrollable form
  Widget _buildStep2Layout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 8),
          Obx(() => controller.errorMessage.value != null
              ? _buildErrorMessage()
              : const SizedBox.shrink()),

          // Pinned preview (always visible)
          _buildBrandingPreview(),
          const SizedBox(height: 12),

          // Scrollable form card
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStep2FormCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (controller.currentStep.value) {
      case 0:
        return _buildStep1PersonalInfo();
      case 1:
        return _buildStep2GymInfo();
      case 2:
        return _buildStep3Branches();
      default:
        return const SizedBox.shrink();
    }
  }

  // =======================================
  // STEP 1: Personal Info
  // =======================================

  Widget _buildStep1PersonalInfo() {
    return _buildCard(
      children: [
        _buildSectionTitle('Datos del Dueño', Icons.person),
        const SizedBox(height: 20),
        _buildTextField(
          controller: controller.firstNameController,
          label: 'Nombre(s)',
          icon: Icons.person_outline,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.lastNameController,
          label: 'Apellidos',
          icon: Icons.person_outline,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.emailController,
          label: 'Correo electrónico',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        Obx(() => _buildTextField(
              controller: controller.passwordController,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              obscureText: controller.obscurePassword.value,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscurePassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: () => controller.obscurePassword.value =
                    !controller.obscurePassword.value,
              ),
            )),
        const SizedBox(height: 16),
        Obx(() => _buildTextField(
              controller: controller.confirmPasswordController,
              label: 'Confirmar contraseña',
              icon: Icons.lock_outline,
              obscureText: controller.obscureConfirmPassword.value,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                icon: Icon(
                  controller.obscureConfirmPassword.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: () => controller.obscureConfirmPassword.value =
                    !controller.obscureConfirmPassword.value,
              ),
            )),
        const SizedBox(height: 28),
        _buildNextButton('Siguiente', () {
          // Validate step 1
          final firstNameError =
              controller.validateFirstName(controller.firstNameController.text);
          final lastNameError =
              controller.validateLastName(controller.lastNameController.text);
          final emailError =
              controller.validateEmail(controller.emailController.text);
          final passError =
              controller.validatePassword(controller.passwordController.text);
          final confirmError = controller.validateConfirmPassword(
              controller.confirmPasswordController.text);

          if (firstNameError != null) {
            controller.errorMessage.value = firstNameError;
            return;
          }
          if (lastNameError != null) {
            controller.errorMessage.value = lastNameError;
            return;
          }
          if (emailError != null) {
            controller.errorMessage.value = emailError;
            return;
          }
          if (passError != null) {
            controller.errorMessage.value = passError;
            return;
          }
          if (confirmError != null) {
            controller.errorMessage.value = confirmError;
            return;
          }

          controller.clearError();
          controller.nextStep();
        }),
      ],
    );
  }

  // =======================================
  // STEP 2: Gym Info
  // =======================================

  Widget _buildStep2GymInfo() {
    // Not used directly anymore — _buildStep2Layout calls the split methods
    return Column(
      children: [
        _buildBrandingPreview(),
        const SizedBox(height: 12),
        _buildStep2FormCard(),
      ],
    );
  }

  /// Compact preview banner — always visible at top of Step 2
  Widget _buildBrandingPreview() {
    return Obx(() {
      final gymText = controller.gymNameText.value.isNotEmpty
          ? controller.gymNameText.value.toUpperCase()
          : 'TU GIMNASIO';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _parseHexColor(controller.selectedBrandColor.value)
                .withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VISTA PREVIA',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.35),
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                gymText,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: _getFontStyle(
                  controller.selectedFont.value,
                  fontSize: 26 *
                      BrandingService.fontSizeMultiplier(
                          controller.selectedFont.value),
                  color: _parseHexColor(controller.selectedBrandColor.value),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Powered by GYMONE',
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withOpacity(0.3),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Form card with gym name, branch, color picker, font picker
  Widget _buildStep2FormCard() {
    final presetColors = [
      '#10D5E8',
      '#FF5733',
      '#FFC300',
      '#28B463',
      '#8E44AD',
      '#3498DB',
      '#E74C3C',
      '#F39C12',
      '#1ABC9C',
      '#E91E63',
    ];

    final fontOptions = [
      'Default',
      'Bebas Neue',
      'Oswald',
      'Montserrat',
      'Poppins',
      'Righteous',
    ];

    return _buildCard(
      children: [
        _buildSectionTitle('Tu Gimnasio', Icons.fitness_center),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.gymNameController,
          label: 'Nombre del gimnasio o cadena',
          icon: Icons.store,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.mainBranchNameController,
          label: 'Nombre de la sucursal principal',
          icon: Icons.location_on_outlined,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 20),

        // Color Picker
        Text(
          'Color de marca',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: presetColors.map((hex) {
                final isSelected = controller.selectedBrandColor.value == hex;
                final color = _parseHexColor(hex);
                return GestureDetector(
                  onTap: () => controller.selectedBrandColor.value = hex,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }).toList(),
            )),
        const SizedBox(height: 20),

        // Font Picker
        Text(
          'Tipografía',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Obx(() {
          final currentFont = controller.selectedFont.value;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fontOptions.map((font) {
              final isSelected = currentFont == font;
              return GestureDetector(
                onTap: () => controller.selectedFont.value = font,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blueAccent.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blueAccent
                          : Colors.white.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    font,
                    style: _getFontStyle(
                      font,
                      fontSize: 13,
                      color: isSelected ? Colors.blueAccent : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
        const SizedBox(height: 24),

        // RFID Reader toggle
        Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.hasRfidReader.value
                      ? Colors.blueAccent.withOpacity(0.5)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.nfc,
                    color: controller.hasRfidReader.value
                        ? Colors.blueAccent
                        : Colors.white38,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Tienes lector RFID?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.hasRfidReader.value
                              ? 'Se buscará al iniciar'
                              : 'Se puede activar después',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: controller.hasRfidReader.value,
                    onChanged: (v) => controller.hasRfidReader.value = v,
                    activeColor: Colors.blueAccent,
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white12,
                  ),
                ],
              ),
            )),
        const SizedBox(height: 24),

        _buildNextButton('Siguiente', () {
          final gymError =
              controller.validateGymName(controller.gymNameController.text);
          final branchError = controller
              .validateBranchName(controller.mainBranchNameController.text);

          if (gymError != null) {
            controller.errorMessage.value = gymError;
            return;
          }
          if (branchError != null) {
            controller.errorMessage.value = branchError;
            return;
          }

          controller.clearError();
          controller.nextStep();
        }),
      ],
    );
  }

  Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF10D5E8);
    }
  }

  TextStyle _getFontStyle(
    String fontName, {
    double fontSize = 14,
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.normal,
    double letterSpacing = 0,
  }) {
    switch (fontName) {
      case 'Bebas Neue':
        return GoogleFonts.bebasNeue(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case 'Oswald':
        return GoogleFonts.oswald(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case 'Montserrat':
        return GoogleFonts.montserrat(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case 'Poppins':
        return GoogleFonts.poppins(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      case 'Righteous':
        return GoogleFonts.righteous(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
      default:
        return TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        );
    }
  }

  // =======================================
  // STEP 3: Optional Branches
  // =======================================

  Widget _buildStep3Branches() {
    return Column(
      children: [
        _buildCard(
          children: [
            _buildSectionTitle('Sucursales Adicionales', Icons.add_business),
            const SizedBox(height: 12),
            Text(
              '¿Tu gimnasio cuenta con más de una sucursal?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => Row(
                  children: [
                    _buildOptionChip(
                      'Sí',
                      controller.wantsMultipleBranches.value,
                      () => controller.toggleMultipleBranches(true),
                    ),
                    const SizedBox(width: 12),
                    _buildOptionChip(
                      'No, solo una',
                      !controller.wantsMultipleBranches.value,
                      () => controller.toggleMultipleBranches(false),
                    ),
                  ],
                )),
            // Additional branch inputs
            Obx(() {
              if (!controller.wantsMultipleBranches.value) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  const SizedBox(height: 20),
                  ...List.generate(controller.additionalBranches.length,
                      (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: controller.additionalBranches[index],
                              label: 'Sucursal ${index + 2}',
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => controller.removeBranch(index),
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: controller.addBranch,
                    icon: const Icon(Icons.add, color: Colors.blueAccent),
                    label: const Text(
                      'Agregar otra sucursal',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 24),
        // Summary card
        _buildCard(
          children: [
            _buildSectionTitle('Resumen', Icons.checklist),
            const SizedBox(height: 12),
            _buildSummaryRow('Dueño', controller.fullName),
            _buildSummaryRow('Email', controller.emailController.text),
            _buildSummaryRow('Gimnasio', controller.gymNameController.text),
            _buildSummaryRow(
                'Sucursal principal', controller.mainBranchNameController.text),
            Obx(() {
              if (!controller.wantsMultipleBranches.value ||
                  controller.additionalBranches.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: controller.additionalBranches
                    .where((c) => c.text.trim().isNotEmpty)
                    .map((c) =>
                        _buildSummaryRow('Sucursal extra', c.text.trim()))
                    .toList(),
              );
            }),
          ],
        ),
        const SizedBox(height: 24),
        // Register button
        Obx(() => _buildRegisterButton()),
      ],
    );
  }

  // =======================================
  // SHARED WIDGETS
  // =======================================

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => this.controller.clearError(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildNextButton(String text, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.register,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: controller.isLoading.value
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Crear Cuenta',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOptionChip(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blueAccent.withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.blueAccent
                  : Colors.white.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.errorMessage.value!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
