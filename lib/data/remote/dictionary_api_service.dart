import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/utils/result.dart';

/// Abstract contract for the remote dictionary data source.
/// WordRepositoryImpl depends on this interface only (Step 7) —
/// keeping the dependency inverted and easily mockable for tests.
abstract class DictionaryApiService {
  /// Fetches raw word data from the Free Dictionary API.
  /// Returns the FIRST entry object from the API's response array
  /// (the API returns a list because a word can have multiple
  /// etymological entries; we use the first/primary one, which
  /// covers the vast majority of practical dictionary use cases).
  Future<Result<Map<String, dynamic>>> fetchWordData(String english);
}

/// HTTP implementation calling https://api.dictionaryapi.dev
///
/// This is the ONLY file in the app that imports package:http.
/// No screen, provider, or repository should ever construct an
/// http.Client directly — everything routes through this service.
class DictionaryApiServiceImpl implements DictionaryApiService {
  DictionaryApiServiceImpl({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<Result<Map<String, dynamic>>> fetchWordData(String english) async {
    final trimmed = english.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return const Result.failure('Cannot look up an empty word.');
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/${Uri.encodeComponent(trimmed)}');

    try {
      final response = await _client.get(uri).timeout(ApiConstants.requestTimeout);

      switch (response.statusCode) {
        case 200:
          return _parseSuccessResponse(response.body);
        case 404:
          return const Result.failure('This word was not found in the online dictionary.');
        case 429:
          return const Result.failure('Too many requests. Please try again in a moment.');
        default:
          return Result.failure('Dictionary service returned an unexpected error (${response.statusCode}).');
      }
    } on SocketException catch (e) {
      return Result.failure('No internet connection.', cause: e);
    } on TimeoutException catch (e) {
      return Result.failure('The request timed out. Please try again.', cause: e);
    } on HttpException catch (e) {
      return Result.failure('A network error occurred.', cause: e);
    } on FormatException catch (e) {
      return Result.failure('Received an invalid response from the server.', cause: e);
    } catch (e) {
      return Result.failure('An unexpected error occurred while fetching word data.', cause: e);
    }
  }

  Result<Map<String, dynamic>> _parseSuccessResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List || decoded.isEmpty) {
        return const Result.failure('No definition data available for this word.');
      }
      final first = decoded.first;
      if (first is! Map<String, dynamic>) {
        return const Result.failure('Unexpected response format from dictionary service.');
      }
      return Result.success(first);
    } catch (e) {
      return Result.failure('Failed to parse dictionary response.', cause: e);
    }
  }

  void dispose() {
    _client.close();
  }
}