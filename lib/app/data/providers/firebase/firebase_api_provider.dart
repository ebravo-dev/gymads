import 'package:gymads/app/data/providers/api_provider.dart';
import 'request_handler.dart';

/// Provider específico para Firebase Firestore
/// Implementa la interfaz ApiProvider para operaciones CRUD
class FirebaseApiProvider extends ApiProvider {
  final String idProject;
  @override
  late String urlBase;

  FirebaseApiProvider({required this.idProject, required String model})
    : super(model: model) {
    urlBase =
        'https://firestore.googleapis.com/v1/projects/$idProject/databases/(default)/documents/$model';
  }

  @override
  Future<Map<String, dynamic>> getAll({Map<String, String>? headers}) async {
    return await sendRequest(Method.GET, urlBase, headers: headers);
  }

  @override
  Future<Map<String, dynamic>> get(
    String id, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(Method.GET, '$urlBase/$id', headers: headers);
  }

  @override
  Future<Map<String, dynamic>> add(
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(
      Method.POST,
      urlBase,
      data: data,
      headers: headers,
    );
  }

  @override
  Future<Map<String, dynamic>> addDocument(
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(
      Method.POST,
      '$urlBase?documentId=$id',
      data: data,
      headers: headers,
    );
  }

  @override
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(
      Method.PATCH,
      '$urlBase/$id',
      data: data,
      headers: headers,
    );
  }

  @override
  Future<Map<String, dynamic>> delete(
    String id, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(Method.DELETE, '$urlBase/$id', headers: headers);
  }
}
