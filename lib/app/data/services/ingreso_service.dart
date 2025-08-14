import '../models/ingreso_model.dart';
import '../models/promotion_model.dart';
import '../providers/ingreso_provider.dart';

/// Servicio para gestionar la lógica de ingresos
class IngresoService {
  final IngresoProvider _ingresoProvider;

  IngresoService({required IngresoProvider ingresoProvider})
      : _ingresoProvider = ingresoProvider;

  /// Calcula y registra el ingreso por registro de nuevo cliente
  Future<bool> registrarIngresoNuevoCliente({
    required String clienteId,
    required String clienteNombre,
    required String tipoMembresia,
    required double precioRegistro,
    required double precioMembresia,
    required String metodoPago,
    required String usuarioStaff,
    PromotionModel? promocion,
    String? notas,
  }) async {
    try {
      double montoBase = precioRegistro + precioMembresia;
      double descuento = 0.0;
      double montoFinal = montoBase;

      // Aplicar promoción si existe
      if (promocion != null && promocion.isActive) {
        final resultadoCalculoPromocion = _calcularDescuentoPromocion(
          montoBase: montoBase,
          precioRegistro: precioRegistro,
          precioMembresia: precioMembresia,
          promocion: promocion,
        );
        
        descuento = resultadoCalculoPromocion['descuento'] ?? 0.0;
        montoFinal = resultadoCalculoPromocion['montoFinal'] ?? montoBase;
      }

      final ingreso = IngresoModel(
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        concepto: 'registro',
        tipoMembresia: tipoMembresia,
        montoBase: precioMembresia,
        cuotaRegistro: precioRegistro,
        descuento: descuento,
        montoFinal: montoFinal,
        promocionId: promocion?.id,
        promocionNombre: promocion?.name,
        metodoPago: metodoPago,
        fecha: DateTime.now(),
        usuarioStaff: usuarioStaff,
        notas: notas,
      );

      print('💰 Registrando ingreso nuevo cliente:');
      print('   - Cliente: $clienteNombre (ID: $clienteId)');
      print('   - Concepto: registro');
      print('   - Tipo membresía: $tipoMembresia');
      print('   - Monto base: \$${precioMembresia.toStringAsFixed(2)}');
      print('   - Cuota registro: \$${precioRegistro.toStringAsFixed(2)}');
      print('   - Descuento: \$${descuento.toStringAsFixed(2)}');
      print('   - Monto final: \$${montoFinal.toStringAsFixed(2)}');
      print('   - Método pago: $metodoPago');
      print('   - Usuario staff: $usuarioStaff');
      print('   - Promoción: ${promocion?.name ?? 'Ninguna'}');
      
      final result = await _ingresoProvider.createIngreso(ingreso);
      print('📝 Resultado de creación de ingreso: $result');
      return result;
    } catch (e) {
      print('❌ Error al registrar ingreso nuevo cliente: $e');
      return false;
    }
  }

  /// Calcula y registra el ingreso por renovación de membresía
  Future<bool> registrarIngresoRenovacion({
    required String clienteId,
    required String clienteNombre,
    required String tipoMembresia,
    required double precioMembresia,
    required String metodoPago,
    required String usuarioStaff,
    PromotionModel? promocion,
    String? notas,
  }) async {
    try {
      double montoBase = precioMembresia;
      double descuento = 0.0;
      double montoFinal = montoBase;

      // Aplicar promoción si existe (las renovaciones no incluyen registro)
      if (promocion != null && promocion.isActive) {
        final resultadoCalculoPromocion = _calcularDescuentoPromocion(
          montoBase: montoBase,
          precioRegistro: 0.0, // No hay registro en renovaciones
          precioMembresia: precioMembresia,
          promocion: promocion,
        );
        
        descuento = resultadoCalculoPromocion['descuento'] ?? 0.0;
        montoFinal = resultadoCalculoPromocion['montoFinal'] ?? montoBase;
      }

      final ingreso = IngresoModel(
        clienteId: clienteId,
        clienteNombre: clienteNombre,
        concepto: 'renovacion',
        tipoMembresia: tipoMembresia,
        montoBase: montoBase,
        cuotaRegistro: 0.0, // No hay cuota de registro en renovaciones
        descuento: descuento,
        montoFinal: montoFinal,
        promocionId: promocion?.id,
        promocionNombre: promocion?.name,
        metodoPago: metodoPago,
        fecha: DateTime.now(),
        usuarioStaff: usuarioStaff,
        notas: notas,
      );

      print('💰 Registrando ingreso renovación:');
      print('   - Cliente: $clienteNombre (ID: $clienteId)');
      print('   - Concepto: renovacion');
      print('   - Tipo membresía: $tipoMembresia');
      print('   - Monto base: \$${montoBase.toStringAsFixed(2)}');
      print('   - Descuento: \$${descuento.toStringAsFixed(2)}');
      print('   - Monto final: \$${montoFinal.toStringAsFixed(2)}');
      print('   - Método pago: $metodoPago');
      print('   - Usuario staff: $usuarioStaff');
      print('   - Promoción: ${promocion?.name ?? 'Ninguna'}');
      
      final result = await _ingresoProvider.createIngreso(ingreso);
      print('📝 Resultado de creación de ingreso renovación: $result');
      return result;
    } catch (e) {
      print('❌ Error al registrar ingreso renovación: $e');
      return false;
    }
  }

  /// Calcula el descuento según el tipo de promoción
  Map<String, double> _calcularDescuentoPromocion({
    required double montoBase,
    required double precioRegistro,
    required double precioMembresia,
    required PromotionModel promocion,
  }) {
    double descuento = 0.0;
    double montoFinal = montoBase;

    switch (promocion.discountType) {
      case 'free_registration':
        // Registro gratis - se descuenta el precio del registro
        if (precioRegistro > 0) {
          descuento = precioRegistro;
          montoFinal = montoBase - descuento;
        }
        break;

      case 'free_membership':
        // Membresía gratis - se descuenta el precio de la membresía
        descuento = precioMembresia;
        montoFinal = montoBase - descuento;
        break;

      case 'percentage':
        // Descuento porcentual
        descuento = montoBase * (promocion.discountValue / 100);
        montoFinal = montoBase - descuento;
        break;

      case 'fixed_amount':
        // Descuento de cantidad fija
        descuento = promocion.discountValue;
        montoFinal = (montoBase - descuento).clamp(0.0, double.infinity);
        break;

      default:
        // Tipo de descuento no reconocido
        print('⚠️ Tipo de descuento no reconocido: ${promocion.discountType}');
        break;
    }

    return {
      'descuento': descuento,
      'montoFinal': montoFinal,
    };
  }

  /// Obtiene estadísticas de ingresos
  Future<EstadisticasIngresos> getEstadisticas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    return await _ingresoProvider.getEstadisticas(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }

  /// Obtiene lista de ingresos con filtros
  Future<List<IngresoModel>> getIngresos({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? concepto,
    String? metodoPago,
    int limit = 100,
  }) async {
    return await _ingresoProvider.getIngresos(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      concepto: concepto,
      metodoPago: metodoPago,
      limit: limit,
    );
  }

  /// Obtiene datos para gráficas por período
  Future<Map<String, double>> getIngresosPorPeriodo({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required String agrupacion,
  }) async {
    return await _ingresoProvider.getIngresosPorPeriodo(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      agrupacion: agrupacion,
    );
  }

  /// Calcula el monto final de una transacción sin registrarla
  Map<String, double> calcularMontoTransaccion({
    required double precioRegistro,
    required double precioMembresia,
    required bool esRenovacion,
    PromotionModel? promocion,
  }) {
    double montoBase = esRenovacion ? precioMembresia : (precioRegistro + precioMembresia);
    double descuento = 0.0;
    double montoFinal = montoBase;

    if (promocion != null && promocion.isActive) {
      final resultado = _calcularDescuentoPromocion(
        montoBase: montoBase,
        precioRegistro: esRenovacion ? 0.0 : precioRegistro,
        precioMembresia: precioMembresia,
        promocion: promocion,
      );
      
      descuento = resultado['descuento'] ?? 0.0;
      montoFinal = resultado['montoFinal'] ?? montoBase;
    }

    return {
      'montoBase': montoBase,
      'descuento': descuento,
      'montoFinal': montoFinal,
    };
  }

  /// Elimina un ingreso (solo para casos especiales de corrección)
  Future<bool> eliminarIngreso(String id) async {
    return await _ingresoProvider.deleteIngreso(id);
  }
}
