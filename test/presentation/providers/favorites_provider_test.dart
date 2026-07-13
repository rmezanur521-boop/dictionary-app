import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:dictionary_app/domain/entities/word_entity.dart';
import 'package:dictionary_app/domain/repositories/favorite_repository.dart';
import 'package:dictionary_app/presentation/providers/favorites_provider.dart';

import 'favorites_provider_test.mocks.dart';

@GenerateMocks([FavoriteRepository])
void main() {
  late MockFavoriteRepository repo;
  late FavoritesProvider provider;

  setUp(() {
    repo = MockFavoriteRepository();
    provider = FavoritesProvider(repo);
  });

  test('loadFavorites transitions loading -> success with data', () async {
    when(repo.getAllFavorites()).thenAnswer((_) async => [
          const WordEntity(id: 1, english: 'cat', bangla: 'বিড়াল'),
        ]);

    final future = provider.loadFavorites();
    expect(provider.status, LoadStatus.loading);
    await future;
    expect(provider.status, LoadStatus.success);
    expect(provider.favorites.length, 1);
  });

  test('loadFavorites transitions to empty when repository returns no data', () async {
    when(repo.getAllFavorites()).thenAnswer((_) async => []);
    await provider.loadFavorites();
    expect(provider.status, LoadStatus.empty);
  });

  test('removeFavorite optimistically removes and returns removed entity', () async {
    when(repo.getAllFavorites()).thenAnswer((_) async => [
          const WordEntity(id: 1, english: 'cat', bangla: 'বিড়াল'),
        ]);
    await provider.loadFavorites();

    when(repo.toggleFavorite(1, false)).thenAnswer((_) async {});
    final removed = await provider.removeFavorite(1);

    expect(removed?.english, 'cat');
    expect(provider.favorites, isEmpty);
    expect(provider.status, LoadStatus.empty);
  });
}