import 'package:flutter/foundation.dart';

/// Converts a Dart map to Firestore's format with typed values.
///
/// This function transforms a standard Dart Map into the specialized
/// structure required by Firestore's REST API.
Map<String, dynamic> toFirestoreValues(Map<String, dynamic>? data) {
  if (data == null) {
    return {'fields': {}};
  }

  Map<String, dynamic> values = {};

  data.forEach((key, value) {
    if (value == null) {
      values[key] = {'nullValue': null};
    } else if (value is String) {
      values[key] = {'stringValue': value};
    } else if (value is double) {
      values[key] = {'doubleValue': value};
    } else if (value is int) {
      values[key] = {
        'integerValue': value.toString(),
      }; // Firestore expects string
    } else if (value is bool) {
      values[key] = {'booleanValue': value};
    } else if (value is DateTime) {
      values[key] = {'timestampValue': value.toUtc().toIso8601String()};
    } else if (value is List) {
      values[key] = {
        'arrayValue': {
          'values':
              value.map((e) {
                if (e is Map<String, dynamic>) {
                  return {'mapValue': toFirestoreValues(e)};
                } else if (e == null) {
                  return {'nullValue': null};
                } else if (e is String) {
                  return {'stringValue': e};
                } else if (e is double) {
                  return {'doubleValue': e};
                } else if (e is int) {
                  return {'integerValue': e.toString()};
                } else if (e is bool) {
                  return {'booleanValue': e};
                } else if (e is DateTime) {
                  return {'timestampValue': e.toUtc().toIso8601String()};
                }
                return e;
              }).toList(),
        },
      };
    } else if (value is Map<String, dynamic>) {
      values[key] = {'mapValue': toFirestoreValues(value)};
    }
  });

  return {'fields': values};
}

Map<String, dynamic> toFirestoreDocument(
  Map<String, dynamic>? data, {
  String? documentId,
}) {
  Map<String, dynamic> document = toFirestoreValues(data);

  if (documentId != null && documentId.isNotEmpty) {
    // Add the document ID to the result
    document['name'] = documentId;
  }

  return document;
}

/// Converts Firestore's document format to standard Dart maps.
///
/// Takes Firestore's REST API response and converts it to a more
/// developer-friendly Dart map structure.
Map<String, dynamic> fromFirestoreValues(Map<String, dynamic> data) {
  if (data.isEmpty) {
    return {};
  }

  try {
    Map<String, dynamic> values = {};

    if (data.containsKey('documents')) {
      for (var document in data['documents']) {
        String docId = document['name'].toString().split('/').last;
        values[docId] = _extractFieldValues(
          document['fields'] ?? {},
          id: docId,
        );
      }
    } else if (data.containsKey('fields')) {
      values = _extractFieldValues(data['fields']);
    }

    return values;
  } catch (e) {
    if (kDebugMode) {
      print('Error parsing Firestore values: $e');
    }
    return {};
  }
}

/// Alias for the original function name for backward compatibility
Map<String, dynamic> getFirestoreValues(Map<String, dynamic> data) {
  return fromFirestoreValues(data);
}

/// Helper function to extract values from Firestore field formats
Map<String, dynamic> _extractFieldValues(
  Map<String, dynamic> fields, {
  String? id,
}) {
  Map<String, dynamic> values = {};
  for (var key in fields.keys) {
    var value = fields[key];
    if (value.containsKey('nullValue')) {
      values[key] = null;
    } else if (value.containsKey('stringValue')) {
      values[key] = value['stringValue'];
    } else if (value.containsKey('doubleValue')) {
      values[key] = value['doubleValue'];
    } else if (value.containsKey('integerValue')) {
      values[key] =
          int.tryParse(value['integerValue'].toString()) ??
          double.tryParse(value['integerValue'].toString());
    } else if (value.containsKey('booleanValue')) {
      values[key] = value['booleanValue'];
    } else if (value.containsKey('timestampValue')) {
      values[key] = DateTime.tryParse(value['timestampValue']);
    } else if (value.containsKey('arrayValue')) {
      final arrayValue = value['arrayValue'];
      if (arrayValue != null && arrayValue.containsKey('values')) {
        values[key] =
            (arrayValue['values'] as List?)
                ?.map(
                  (e) => e is Map<String, dynamic> ? _extractSingleValue(e) : e,
                )
                .toList() ??
            [];
      } else {
        values[key] = [];
      }
    } else if (value.containsKey('mapValue')) {
      final mapValue = value['mapValue'];
      if (mapValue != null && mapValue.containsKey('fields')) {
        values[key] = _extractFieldValues(mapValue['fields']);
      } else {
        values[key] = {};
      }
    }
  }
  if (id != null) values['id'] = id;
  return values;
}

dynamic _extractSingleValue(Map<String, dynamic> value) {
  if (value.containsKey('mapValue') &&
      value['mapValue'].containsKey('fields')) {
    return _extractFieldValues(value['mapValue']['fields']);
  } else if (value.containsKey('stringValue')) {
    return value['stringValue'];
  } else if (value.containsKey('doubleValue')) {
    return value['doubleValue'];
  } else if (value.containsKey('integerValue')) {
    return int.tryParse(value['integerValue'].toString()) ??
        double.tryParse(value['integerValue'].toString());
  } else if (value.containsKey('booleanValue')) {
    return value['booleanValue'];
  } else if (value.containsKey('timestampValue')) {
    return DateTime.tryParse(value['timestampValue']);
  } else if (value.containsKey('nullValue')) {
    return null;
  }
  return null;
}
