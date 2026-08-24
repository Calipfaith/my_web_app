import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? accessToken;
  static String? idToken;
  static String? refreshToken;
  static int? expiresAt;
  final http.Client client;
  final String baseUrl;
  final String hostedDomain;
  final String clientId;
  final String redirectUri;
  String? _codeVerifier;

  AuthService({
    http.Client? client,
    String? baseUrl,
    String? hostedDomain,
    String? clientId,
    String? redirectUri,
  }) : client = client ?? http.Client(),
       baseUrl =
           baseUrl ??
           const String.fromEnvironment('CATALOG_API_URL', defaultValue: ''),
       hostedDomain =
           hostedDomain ??
           const String.fromEnvironment(
             'COGNITO_HOSTED_DOMAIN',
             defaultValue: '',
           ),
       clientId =
           clientId ??
           const String.fromEnvironment(
             'COGNITO_APP_CLIENT_ID',
             defaultValue: '',
           ),
       redirectUri =
           redirectUri ??
           const String.fromEnvironment(
             'COGNITO_REDIRECT_URI',
             defaultValue: 'http://localhost:8081/',
           );

  Uri getLoginUri(Uri redirectUri) {
    if (hostedDomain.isEmpty || clientId.isEmpty)
      throw StateError('Cognito Hosted UI is not configured');
    final random = Random.secure();
    _codeVerifier = base64Url
        .encode(List<int>.generate(32, (_) => random.nextInt(256)))
        .replaceAll('=', '');
    return Uri.parse(
      '${hostedDomain.replaceFirst(RegExp(r'/$'), '')}/oauth2/authorize',
    ).replace(
      queryParameters: {
        'client_id': clientId,
        'response_type': 'code',
        'scope': 'openid email',
        'redirect_uri': redirectUri.toString(),
        'state': _codeVerifier!,
        'code_challenge_method': 'S256',
        'code_challenge': base64Url
            .encode(sha256.convert(utf8.encode(_codeVerifier!)).bytes)
            .replaceAll('=', ''),
      },
    );
  }

  Future<Map<String, dynamic>> exchangeCode(
    String code,
    Uri redirectUri, {
    String? codeVerifier,
  }) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/auth/token'
        : '$baseUrl/api/auth/token';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'redirectUri': redirectUri.toString(),
        'codeVerifier': codeVerifier ?? _codeVerifier,
      }),
    );
    if (response.statusCode != 200)
      throw Exception('Cognito token exchange failed: ${response.statusCode}');
    final tokens = jsonDecode(response.body) as Map<String, dynamic>;
    accessToken = tokens['access_token'] as String?;
    idToken = tokens['id_token'] as String?;
    refreshToken = tokens['refresh_token'] as String?;
    expiresAt =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        ((tokens['expires_in'] as num?)?.toInt() ?? 3600);
    await _persistSession();
    return tokens;
  }

  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('auth_access_token');
    idToken = prefs.getString('auth_id_token');
    refreshToken = prefs.getString('auth_refresh_token');
    expiresAt = prefs.getInt('auth_expires_at');
    if (expiresAt != null &&
        expiresAt! <= DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      if (refreshToken == null) {
        signOut();
      } else {
        try {
          await AuthService().refreshSession(refreshToken!);
        } catch (_) {
          signOut();
        }
      }
    }
  }

  Future<void> refreshSession(String token) async {
    final endpoint = baseUrl.isEmpty
        ? '/api/auth/refresh'
        : '$baseUrl/api/auth/refresh';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': token}),
    );
    if (response.statusCode != 200)
      throw Exception('Cognito refresh failed: ${response.statusCode}');
    final tokens = jsonDecode(response.body) as Map<String, dynamic>;
    accessToken = tokens['access_token'] as String?;
    expiresAt =
        DateTime.now().millisecondsSinceEpoch ~/ 1000 +
        ((tokens['expires_in'] as num?)?.toInt() ?? 3600);
    await _persistSession();
  }

  static Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null)
      await prefs.setString('auth_access_token', accessToken!);
    if (idToken != null) await prefs.setString('auth_id_token', idToken!);
    if (refreshToken != null)
      await prefs.setString('auth_refresh_token', refreshToken!);
    if (expiresAt != null) await prefs.setInt('auth_expires_at', expiresAt!);
  }

  static Map<String, String> authHeaders() => accessToken == null
      ? <String, String>{}
      : {'Authorization': 'Bearer $accessToken'};

  static String? get displayName {
    if (idToken == null) return null;
    try {
      final parts = idToken!.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      return (payload['name'] ?? payload['email'] ?? payload['username'])
          as String?;
    } catch (_) {
      return null;
    }
  }

  static String? get email {
    if (idToken == null) return null;
    try {
      final parts = idToken!.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      return payload['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  static List<String> get groups {
    if (idToken == null) return const [];
    try {
      final parts = idToken!.split('.');
      if (parts.length != 3) return const [];
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      return (payload['cognito:groups'] as List<dynamic>? ?? const [])
          .cast<String>();
    } catch (_) {
      return const [];
    }
  }

  static bool get isQueen =>
      groups.any((group) => group.toLowerCase() == 'queen');

  static bool get isBee => groups.any((group) => group.toLowerCase() == 'bee');

  static void signOut() {
    accessToken = null;
    idToken = null;
    refreshToken = null;
    expiresAt = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('auth_access_token');
      prefs.remove('auth_id_token');
      prefs.remove('auth_refresh_token');
      prefs.remove('auth_expires_at');
    });
  }

  Future<void> revokeSession() async {
    if (refreshToken == null) {
      signOut();
      return;
    }
    final endpoint = baseUrl.isEmpty
        ? '/api/auth/revoke'
        : '$baseUrl/api/auth/revoke';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (response.statusCode != 200)
      throw Exception('Cognito revoke failed: ${response.statusCode}');
    signOut();
  }
}
