import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dictionary_app/domain/entities/word_entity.dart';
import 'package:dictionary_app/presentation/widgets/word_card.dart';

void main() {
  testWidgets('WordCard displays english/bangla and responds to tap', (tester) async {
    var tapped = false;
    const word = WordEntity(id: 1, english: 'hello', bangla: 'হ্যালো', partOfSpeech: 'exclamation');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WordCard(word: word, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('hello'), findsOneWidget);
    expect(find.text('হ্যালো'), findsOneWidget);
    expect(find.text('exclamation'), findsOneWidget);

    await tester.tap(find.byType(WordCard));
    expect(tapped, true);
  });

  testWidgets('WordCard shows placeholder when bangla translation missing', (tester) async {
    const word = WordEntity(id: 2, english: 'xenial', bangla: '');

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: WordCard(word: word, onTap: () {}))),
    );

    expect(find.text('অনুবাদ পাওয়া যায়নি'), findsOneWidget);
  });
}