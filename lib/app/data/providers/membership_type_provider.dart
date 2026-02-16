import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membership_type_model.dart';
import '../services/tenant_query_helper.dart';

class MembershipTypeProvider {
  final SupabaseClient _client = Supabase.instance.client;
  final String _table = 'membership_types';

  // Obtener todos los tipos de membresía (por defecto solo activas)
  Future<List<MembershipTypeModel>> getMembershipTypes(
      {bool onlyActive = true}) async {
    try {
      var query = _client
          .from(_table)
          .select()
          .eq('gym_id', TenantQueryHelper.gymIdOrNull ?? '');

      // Aplicar filtro solo si se solicitan únicamente las activas
      if (onlyActive) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('name', ascending: true);

      List<MembershipTypeModel> result = [];
      for (var item in response) {
        result.add(MembershipTypeModel.fromMap(item, item['id'].toString()));
      }

      return result;
    } catch (e) {
      print('Error al obtener tipos de membresía: $e');
      throw Exception('Error al cargar tipos de membresía: $e');
    }
  }

  // Obtener un tipo de membresía por ID
  Future<MembershipTypeModel?> getMembershipTypeById(String id) async {
    try {
      final response =
          await _client.from(_table).select().eq('id', id).single();

      return MembershipTypeModel.fromMap(response, id);
    } catch (e) {
      print('Error al obtener tipo de membresía: $e');
      return null;
    }
  }

  // Crear un nuevo tipo de membresía
  Future<MembershipTypeModel?> createMembershipType(
      MembershipTypeModel membershipType) async {
    try {
      final response = await _client
          .from(_table)
          .insert(TenantQueryHelper.withGym({
            'name': membershipType.name,
            'description': membershipType.description,
            'price': membershipType.price,
            'duration_days': membershipType.durationDays,
            'is_active': membershipType.isActive
          }))
          .select()
          .single();

      return MembershipTypeModel.fromMap(response, response['id'].toString());
    } catch (e) {
      print('Error al crear tipo de membresía: $e');
      throw Exception('Error al crear tipo de membresía: $e');
    }
  }

  // Actualizar un tipo de membresía existente
  Future<MembershipTypeModel?> updateMembershipType(
      MembershipTypeModel membershipType) async {
    try {
      if (membershipType.id == null) {
        throw Exception('No se puede actualizar un tipo de membresía sin ID');
      }

      final response = await _client
          .from(_table)
          .update({
            'name': membershipType.name,
            'description': membershipType.description,
            'price': membershipType.price,
            'duration_days': membershipType.durationDays,
            'is_active': membershipType.isActive,
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', membershipType.id!)
          .select()
          .single();

      return MembershipTypeModel.fromMap(response, membershipType.id!);
    } catch (e) {
      print('Error al actualizar tipo de membresía: $e');
      throw Exception('Error al actualizar tipo de membresía: $e');
    }
  }

  // Cambiar el estado de un tipo de membresía (activar/desactivar)
  Future<bool> toggleMembershipTypeStatus(String id, bool isActive) async {
    try {
      await _client.from(_table).update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', id);

      return true;
    } catch (e) {
      print('Error al cambiar estado del tipo de membresía: $e');
      return false;
    }
  }

  // Eliminar un tipo de membresía
  Future<bool> deleteMembershipType(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);

      return true;
    } catch (e) {
      print('Error al eliminar tipo de membresía: $e');
      return false;
    }
  }
}
