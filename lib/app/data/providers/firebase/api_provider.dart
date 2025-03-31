import 'request_handler.dart';

class FirebaseApiProvider {
  final String idProject;
  final String model;
  late String urlBase;

  FirebaseApiProvider({required this.idProject, required this.model}) {
    urlBase =
        'https://firestore.googleapis.com/v1/projects/$idProject/databases/(default)/documents/$model';
  }

  Future<Map<String, dynamic>> getAll({Map<String, String>? headers}) async {
    return await sendRequest(Method.GET, urlBase, headers: headers);
  }

  Future<Map<String, dynamic>> get(
    String id, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(Method.GET, '$urlBase/$id', headers: headers);
  }

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

  Future<Map<String, dynamic>> addDocument(
    String id,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(
      Method.POST,
      '$urlBase/$id',
      data: data,
      headers: headers,
    );
  }

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

  Future<Map<String, dynamic>> delete(
    String id, {
    Map<String, String>? headers,
  }) async {
    return await sendRequest(Method.DELETE, '$urlBase/$id', headers: headers);
  }
}
