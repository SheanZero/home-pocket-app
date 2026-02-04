import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'repository_providers.dart';

part 'current_book_provider.g.dart';

/// Provider for current book ID
///
/// Returns the ID of the first active (non-archived) book.
/// Returns null if no books exist.
///
/// TODO: Replace with user-selectable book when multi-book UI is implemented
@riverpod
Future<String?> currentBookId(CurrentBookIdRef ref) async {
  final bookRepo = ref.watch(bookRepositoryProvider);
  final books = await bookRepo.findAll();

  // Get first non-archived book
  final activeBooks = books.where((book) => !book.isArchived).toList();

  if (activeBooks.isEmpty) {
    return null; // No books available
  }

  return activeBooks.first.id;
}
