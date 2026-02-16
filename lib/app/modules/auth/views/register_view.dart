import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 8),
          // Error message
          Obx(() => controller.errorMessage.value != null
              ? _buildErrorMessage()
              : const SizedBox.shrink()),
          // Step content
          _buildStepContent(),
          const SizedBox(height: 24),
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
    return _buildCard(
      children: [
        _buildSectionTitle('Tu Gimnasio', Icons.fitness_center),
        const SizedBox(height: 20),
        _buildTextField(
          controller: controller.gymNameController,
          label: 'Nombre del gimnasio o cadena',
          icon: Icons.store,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.mainBranchNameController,
          label: 'Nombre de la sucursal principal',
          icon: Icons.location_on_outlined,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 28),
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
