import 'dart:math';

const List<String> warmEmojis = [
  '🏠',
  '🌸',
  '🌿',
  '🐱',
  '🐶',
  '🌈',
  '☀️',
  '🦊',
  '🐼',
  '🍀',
  '⭐',
  '🌻',
  '🐰',
  '🦋',
  '🌙',
  '🎀',
  '🧸',
  '🎵',
  '🏡',
  '🌷',
  '🐣',
  '🍃',
  '💫',
  '🫧',
];

final _random = Random();

String randomWarmEmoji() => warmEmojis[_random.nextInt(warmEmojis.length)];
