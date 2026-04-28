import 'dart:convert';
import 'dart:io';

/// One-command Firebase seed for chat testing.
///
/// Usage:
///   dart run tool/seed_demo_data.dart
///
/// Optional env overrides:
///   FIREBASE_PROJECT_ID
///   FIREBASE_API_KEY
///   DEMO_PASSWORD
const String defaultProjectId = 'classmates1project';
const String defaultApiKey = 'AIzaSyBTseQgh5YN32tkfhSNZ-V1sVkb89-WXZI';
const String defaultPassword = 'Classmate@123';

const String aliceName = 'Alice Demo';
const String aliceEmail = 'alice.demo.classmate@gmail.com';
const String bobName = 'Bob Demo';
const String bobEmail = 'bob.demo.classmate@gmail.com';

Future<void> main() async {
  final projectId =
      Platform.environment['FIREBASE_PROJECT_ID'] ?? defaultProjectId;
  final apiKey = Platform.environment['FIREBASE_API_KEY'] ?? defaultApiKey;
  final password = Platform.environment['DEMO_PASSWORD'] ?? defaultPassword;

  stdout.writeln('Seeding demo users into project: $projectId');

  final alice = await _ensureAccount(
    apiKey: apiKey,
    email: aliceEmail,
    password: password,
    displayName: aliceName,
  );
  final bob = await _ensureAccount(
    apiKey: apiKey,
    email: bobEmail,
    password: password,
    displayName: bobName,
  );

  await _upsertUserDoc(
    projectId: projectId,
    idToken: alice.idToken,
    uid: alice.uid,
    name: aliceName,
    email: aliceEmail,
  );
  await _upsertUserDoc(
    projectId: projectId,
    idToken: bob.idToken,
    uid: bob.uid,
    name: bobName,
    email: bobEmail,
  );

  final chatId = _buildChatId(alice.uid, bob.uid);
  await _upsertChatDoc(
    projectId: projectId,
    idToken: alice.idToken,
    chatId: chatId,
    aliceUid: alice.uid,
    bobUid: bob.uid,
  );

  await _createMessage(
    projectId: projectId,
    idToken: alice.idToken,
    chatId: chatId,
    senderUid: alice.uid,
    receiverUid: bob.uid,
    text: 'Hi Bob! This is a seeded test message.',
  );

  stdout.writeln('Seed complete.');
  stdout.writeln('Sign in using either account:');
  stdout.writeln('  $aliceEmail / $password');
  stdout.writeln('  $bobEmail / $password');
}

String _buildChatId(String a, String b) {
  final ids = [a, b]..sort();
  return '${ids[0]}_${ids[1]}';
}

class _AuthResult {
  _AuthResult({required this.uid, required this.idToken});

  final String uid;
  final String idToken;
}

class _HttpResult {
  _HttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

Future<_AuthResult> _ensureAccount({
  required String apiKey,
  required String email,
  required String password,
  required String displayName,
}) async {
  final signUpUri = Uri.parse(
    'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
  );

  final signUpBody = {
    'email': email,
    'password': password,
    'returnSecureToken': true,
  };

  final signUpResponse = await _postJson(signUpUri, signUpBody);

  if (signUpResponse.statusCode == 200) {
    final data = jsonDecode(signUpResponse.body) as Map<String, dynamic>;
    return _AuthResult(
      uid: data['localId'] as String,
      idToken: data['idToken'] as String,
    );
  }

  final errorData = jsonDecode(signUpResponse.body) as Map<String, dynamic>;
  final errorCode =
      ((errorData['error'] as Map<String, dynamic>?)?['message'] ?? '')
          .toString();

  if (errorCode == 'EMAIL_EXISTS') {
    final signInUri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
    );
    final signInBody = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };
    final signInResponse = await _postJson(signInUri, signInBody);
    if (signInResponse.statusCode != 200) {
      throw Exception(
        'Could not sign in existing account $email: ${signInResponse.body}',
      );
    }
    final signInData = jsonDecode(signInResponse.body) as Map<String, dynamic>;
    return _AuthResult(
      uid: signInData['localId'] as String,
      idToken: signInData['idToken'] as String,
    );
  }

  throw Exception('Could not create account $email: ${signUpResponse.body}');
}

Future<void> _upsertUserDoc({
  required String projectId,
  required String idToken,
  required String uid,
  required String name,
  required String email,
}) async {
  final uri = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid',
  );

  final payload = {
    'fields': {
      'uid': {'stringValue': uid},
      'name': {'stringValue': name},
      'email': {'stringValue': email},
      'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    },
  };

  final response = await _patchJson(uri, payload, idToken: idToken);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Could not upsert user doc for $email: ${response.body}');
  }
}

Future<void> _upsertChatDoc({
  required String projectId,
  required String idToken,
  required String chatId,
  required String aliceUid,
  required String bobUid,
}) async {
  final uri = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/chats/$chatId',
  );

  final payload = {
    'fields': {
      'participants': {
        'arrayValue': {
          'values': [
            {'stringValue': aliceUid},
            {'stringValue': bobUid},
          ],
        },
      },
      'usernames': {
        'mapValue': {
          'fields': {
            aliceUid: {'stringValue': aliceName},
            bobUid: {'stringValue': bobName},
          },
        },
      },
      'lastMessage': {'stringValue': 'Hi Bob! This is a seeded test message.'},
      'lastTimestamp': {
        'timestampValue': DateTime.now().toUtc().toIso8601String(),
      },
    },
  };

  final response = await _patchJson(uri, payload, idToken: idToken);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Could not upsert chat doc: ${response.body}');
  }
}

Future<void> _createMessage({
  required String projectId,
  required String idToken,
  required String chatId,
  required String senderUid,
  required String receiverUid,
  required String text,
}) async {
  final uri = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/messages',
  );

  final payload = {
    'fields': {
      'chatId': {'stringValue': chatId},
      'senderId': {'stringValue': senderUid},
      'receiverId': {'stringValue': receiverUid},
      'text': {'stringValue': text},
      'timestamp': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      'read': {'booleanValue': false},
      'readAt': {'nullValue': null},
      'readBy': {'nullValue': null},
    },
  };

  final response = await _postJson(uri, payload, idToken: idToken);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Could not create seed message: ${response.body}');
  }
}

Future<_HttpResult> _postJson(
  Uri uri,
  Map<String, dynamic> body, {
  String? idToken,
}) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    if (idToken != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    }
    request.write(jsonEncode(body));
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    return _HttpResult(statusCode: response.statusCode, body: responseBody);
  } finally {
    client.close(force: false);
  }
}

Future<_HttpResult> _patchJson(
  Uri uri,
  Map<String, dynamic> body, {
  required String idToken,
}) async {
  final client = HttpClient();
  try {
    final request = await client.patchUrl(uri);
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
    request.write(jsonEncode(body));
    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    return _HttpResult(statusCode: response.statusCode, body: responseBody);
  } finally {
    client.close(force: false);
  }
}
