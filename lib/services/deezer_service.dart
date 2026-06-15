import 'dart:convert';
import 'package:http/http.dart' as http;

class DeezerService {
  Future<List<dynamic>> searchSongs(String query) async {
    try {
      String finalQuery = query;
      final lowerQuery = query.toLowerCase();
      if (!lowerQuery.contains('indie') &&
          !lowerQuery.contains('alternative') &&
          !lowerQuery.contains('shoegaze') &&
          !lowerQuery.contains('post-punk') &&
          !lowerQuery.contains('post punk') &&
          !lowerQuery.contains('lo-fi') &&
          !lowerQuery.contains('dream pop') &&
          !lowerQuery.contains('folk')) {
        finalQuery = '$query indie';
      }

      final encodedQuery = Uri.encodeComponent(finalQuery);

      final response = await http.get(
        Uri.parse(
          'https://corsproxy.io/?https://api.deezer.com/search?q=$encodedQuery',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }

      return [];
    } catch (e) {
      print('Erro Deezer: $e');
      return [];
    }
  }
}
