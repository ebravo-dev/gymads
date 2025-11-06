import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gymads/app/data/models/user_model.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/app/global_widgets/qr_dialog.dart';
import '../../../core/widgets/cached_user_image.dart';
import '../controllers/clientes_controller.dart';

class ClienteDetailView extends GetView<ClientesController> {
  final UserModel cliente;

  const ClienteDetailView({
    super.key,
    required this.cliente,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar moderno con gradiente
          _buildSliverAppBar(),
          
          // Contenido principal
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Header con información principal
                    _buildHeaderCard(),
                    
                    const SizedBox(height: 20),
                    
                    // Cards de información rápida
                    _buildQuickInfoCards(),
                    
                    const SizedBox(height: 20),
                    
                    // Información detallada
                    _buildDetailCards(),
                    
                    const SizedBox(height: 20),
                    
                    // Botones de acción
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.backgroundColor,
                AppColors.cardBackground,
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: constraints.maxHeight * 0.15),
                        // Avatar del cliente
                        Hero(
                          tag: 'cliente-${cliente.id}',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _getStatusColor(),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor().withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: UserProfileImage(
                              imageUrl: cliente.photoUrl,
                              userName: cliente.name,
                              size: 100,
                              showBorder: false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Nombre del cliente
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            cliente.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.titleColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // ID del cliente
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.containerBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.titleColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'ID: ${cliente.userNumber}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.1),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: AppColors.titleColor,
        ),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.titleColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.titleColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Estado del cliente
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusChip(),
              if (cliente.needsRenewal || !cliente.isActive)
                _buildDaysRemaining(),
            ],
          ),
          const SizedBox(height: 20),
          
          // Información de membresía
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Membresía',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cliente.membershipType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '\$${cliente.membershipPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysRemaining() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '${cliente.daysRemaining} días',
        style: const TextStyle(
          color: AppColors.warning,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildQuickInfoCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Primera fila: Teléfono y RFID
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.phone_outlined,
                  title: 'Teléfono',
                  value: cliente.phone,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.credit_card_outlined,
                  title: 'RFID',
                  value: cliente.rfidCard ?? 'No asignada',
                  color: cliente.rfidCard != null ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Segunda fila: QR Code (centrado, más ancho)
          _buildQrCard(),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.titleColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.titleColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con icono y título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.titleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.qr_code_outlined,
                  color: AppColors.titleColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Código QR de Acceso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Botón de acción
          _buildQrActionButton(
            label: 'Ver QR',
            icon: Icons.visibility_outlined,
            color: AppColors.info,
            onPressed: _showQrDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildQrActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 120, // Altura fija para que tengan el mismo tamaño
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(), // Empuja el texto hacia abajo
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Card de fechas importantes
          _buildDetailCard(
            title: 'Fechas Importantes',
            icon: Icons.calendar_today_outlined,
            children: [
              _buildDetailRow(
                'Fecha de registro',
                _formatDate(cliente.joinDate),
                Icons.today_outlined,
              ),
              if (cliente.expirationDate != null)
                _buildDetailRow(
                  'Fecha de expiración',
                  _formatDate(cliente.expirationDate!),
                  Icons.event_outlined,
                ),
              if (cliente.lastPaymentDate != null)
                _buildDetailRow(
                  'Último pago',
                  _formatDate(cliente.lastPaymentDate!),
                  Icons.payment_outlined,
                ),
            ],
          ),
          
          if (!cliente.isActive) ...[
            const SizedBox(height: 16),
            // Card de información adicional
            _buildDetailCard(
              title: 'Información Adicional',
              icon: Icons.info_outline,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cliente.isNewRegistration() 
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cliente.isNewRegistration() 
                          ? AppColors.error.withOpacity(0.3)
                          : AppColors.info.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        cliente.isNewRegistration() ? Icons.warning_outlined : Icons.info_outlined,
                        color: cliente.isNewRegistration() ? AppColors.error : AppColors.info,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cliente.isNewRegistration()
                              ? 'Requiere pago de registro nuevo (\$${UserModel.registrationFee.toStringAsFixed(0)})'
                              : 'Puede renovar sin costo adicional',
                          style: TextStyle(
                            color: cliente.isNewRegistration() ? AppColors.error : AppColors.info,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.titleColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.titleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.titleColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Renovar',
                  icon: Icons.refresh_outlined,
                  color: AppColors.success,
                  onPressed: _renovarCliente,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  label: 'Editar',
                  icon: Icons.edit_outlined,
                  color: AppColors.titleColor,
                  onPressed: _editCliente,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: 'Eliminar Cliente',
            icon: Icons.delete_outline,
            color: AppColors.error,
            onPressed: _deleteCliente,
            isOutlined: true,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 52,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 1.5),
                backgroundColor: color.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: color.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
    );
  }

  // Helper methods para el estado
  Color _getStatusColor() {
    if (!cliente.isActive) return AppColors.error;
    if (cliente.needsRenewal) return AppColors.warning;
    return AppColors.success;
  }

  IconData _getStatusIcon() {
    if (!cliente.isActive) return Icons.cancel;
    if (cliente.needsRenewal) return Icons.warning;
    return Icons.check_circle;
  }

  String _getStatusText() {
    if (!cliente.isActive) return 'Inactivo';
    if (cliente.needsRenewal) return 'Por vencer';
    return 'Activo';
  }

  // Funciones para manejar las acciones
  void _editCliente() {
    Get.back(); // Volver a la lista de clientes
    Get.snackbar(
      'Editar',
      'Redirigiendo a edición de cliente...',
      snackPosition: SnackPosition.BOTTOM,
    );
    // La lógica de edición se manejará desde la vista principal
  }

  void _renovarCliente() {
    Get.back(); // Volver a la lista de clientes
    Get.snackbar(
      'Renovar',
      'Redirigiendo a renovación de membresía...',
      snackPosition: SnackPosition.BOTTOM,
    );
    // La lógica de renovación se manejará desde la vista principal
  }

  void _deleteCliente() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Eliminar Cliente',
          style: TextStyle(
            color: AppColors.titleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${cliente.name}?\n\nEsta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // Cerrar dialog
              Get.back(); // Volver a lista
              controller.deleteCliente(cliente.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Métodos para manejar las acciones del QR
  void _showQrDialog() {
    Get.dialog(
      QrDialog(
        nombre: cliente.name,
        telefono: cliente.phone,
        userNumber: cliente.userNumber,
        totalAmount: cliente.membershipPrice,
      ),
    );
  }
}
