import 'package:flutter/material.dart';
import 'package:gymads/core/theme/app_colors.dart';
import 'package:gymads/core/utils/responsive_utils.dart';
import '../../../data/models/membership_type_model.dart';

class MembershipCard extends StatelessWidget {
  final MembershipTypeModel membership;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const MembershipCard({
    Key? key,
    required this.membership,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = membership.isActive;
    
    return Card(
      color: AppColors.cardBackground,
      elevation: 2,
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveValues.getSpacing(context, 
          mobile: 8, 
          tablet: 12, 
          desktop: 16
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isActive ? AppColors.success : AppColors.error,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveValues.getSpacing(context, 
          mobile: 12, 
          tablet: 16, 
          desktop: 20
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con nombre y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    membership.name,
                    style: TextStyle(
                      fontSize: ResponsiveValues.getFontSize(context, 
                        mobile: 16, 
                        tablet: 18, 
                        desktop: 20
                      ),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success : AppColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Activa' : 'Inactiva',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveValues.getFontSize(context, 
                        mobile: 12, 
                        tablet: 14, 
                        desktop: 16
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: ResponsiveValues.getSpacing(context, 
              mobile: 8, 
              tablet: 12, 
              desktop: 16
            )),
            
            // Descripción
            Text(
              membership.description,
              style: TextStyle(
                fontSize: ResponsiveValues.getFontSize(context, 
                  mobile: 14, 
                  tablet: 16, 
                  desktop: 18
                ),
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: ResponsiveValues.getSpacing(context, 
              mobile: 12, 
              tablet: 16, 
              desktop: 20
            )),
            
            // Precio
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.titleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '\$${membership.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: ResponsiveValues.getFontSize(context, 
                    mobile: 16, 
                    tablet: 18, 
                    desktop: 20
                  ),
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleColor,
                ),
              ),
            ),
            
            SizedBox(height: ResponsiveValues.getSpacing(context, 
              mobile: 8, 
              tablet: 12, 
              desktop: 16
            )),
            
            // Duración
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: ResponsiveValues.getIconSize(context, 
                    mobile: 16, 
                    tablet: 18, 
                    desktop: 20
                  ),
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: ResponsiveValues.getSpacing(context, 
                  mobile: 4, 
                  tablet: 6, 
                  desktop: 8
                )),
                Text(
                  'Duración: ${membership.durationDays} días',
                  style: TextStyle(
                    fontSize: ResponsiveValues.getFontSize(context, 
                      mobile: 14, 
                      tablet: 16, 
                      desktop: 18
                    ),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: ResponsiveValues.getSpacing(context, 
              mobile: 16, 
              tablet: 20, 
              desktop: 24
            )),
            
            // Botones de acción más compactos, similares a la vista de clientes
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón de editar
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.info),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                ),
                
                // Botón de activar/desactivar
                IconButton(
                  icon: Icon(
                    isActive ? Icons.unpublished : Icons.check_circle,
                    color: isActive ? AppColors.warning : AppColors.success,
                  ),
                  onPressed: onToggleActive,
                  tooltip: isActive ? 'Desactivar' : 'Activar',
                ),
                
                // Botón de eliminar
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: onDelete,
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
