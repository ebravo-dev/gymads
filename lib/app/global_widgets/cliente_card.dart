import 'package:flutter/material.dart';
import 'package:gymads/app/data/models/user_model.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ClienteCard extends StatelessWidget {
  final UserModel cliente;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRenovar;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onRenovar,
  });

  @override
  Widget build(BuildContext context) {
    // Capitalizar primera letra del tipo de membresía
    final membershipType =
        cliente.membershipType[0].toUpperCase() +
        cliente.membershipType.substring(1);

    // Formatear fecha de expiración
    final expirationDate =
        cliente.expirationDate != null
            ? DateFormat('dd/MM/yyyy').format(cliente.expirationDate!)
            : 'N/A';

    // Determinar colores según el estado
    final Color primaryColor =
        cliente.isActive
            ? cliente.needsRenewal
                ? AppColors.warning
                : AppColors.info
            : AppColors.error;

    final Color statusColor = primaryColor.withOpacity(0.1);

    // Texto del estado
    final String statusText =
        cliente.isActive
            ? cliente.needsRenewal
                ? 'Por vencer'
                : 'Activo'
            : 'Inactivo';

    // Icono según el estado
    final IconData statusIcon =
        cliente.isActive
            ? cliente.needsRenewal
                ? Icons.warning_rounded
                : Icons.check_circle_rounded
            : Icons.cancel_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                // Encabezado con estado
                Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 20, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (cliente.isActive && cliente.expirationDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${cliente.daysRemaining} días',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Contenido principal
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar del cliente
                      Hero(
                        tag: 'avatar_${cliente.id}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withOpacity(0.5),
                              width: 2,
                            ),
                            // boxShadow: [
                            //   BoxShadow(
                            //     color: primaryColor.withOpacity(0.2),
                            //     blurRadius: 3,
                            //     spreadRadius: 5,
                            //   ),
                            // ],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.cardBackground,
                            backgroundImage:
                                cliente.photoUrl != null
                                    ? NetworkImage(cliente.photoUrl!)
                                    : null,
                            child:
                                cliente.photoUrl == null
                                    ? Text(
                                      cliente.name.isNotEmpty
                                          ? cliente.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Información del cliente
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre del cliente con badge de ID
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cliente.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'ID: ${cliente.userNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Detalles de la membresía
                            _buildInfoRow(
                              Icons.card_membership_rounded,
                              '$membershipType (\$${cliente.membershipPrice.toStringAsFixed(0)})',
                              primaryColor,
                            ),
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              Icons.event_available_rounded,
                              'Expira: $expirationDate',
                              primaryColor,
                            ),
                            const SizedBox(height: 6),
                            _buildInfoRow(
                              Icons.phone_rounded,
                              cliente.phone,
                              primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Separador
                Divider(
                  height: 1,
                  thickness: 1,
                  color: primaryColor.withOpacity(0.2),
                ),

                // Acciones
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        onEdit,
                        Icons.edit_rounded,
                        'Editar',
                        Colors.green.shade300,
                      ),
                      _buildActionButton(
                        onDelete,
                        Icons.delete_rounded,
                        'Eliminar',
                        Colors.red.shade300,
                      ),
                      // _buildActionButton(
                      //   onRenovar,
                      //   Icons.update_rounded,
                      //   'Renovar',
                      //   Colors.yellow.shade300,
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para filas de información
  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Widget para botones de acción
  Widget _buildActionButton(
    VoidCallback onPressed,
    IconData icon,
    String label,
    Color color,
  ) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
