/// Persisted identifiers for the warm avatar icons offered by the app.
///
/// The `icon:` prefix keeps these values distinguishable from legacy emoji
/// avatars while remaining compatible with the existing string storage field.
const List<String> avatarIconIds = [
  'icon:user-round',
  'icon:cat',
  'icon:dog',
  'icon:rabbit',
  'icon:bird',
  'icon:flower',
  'icon:leaf',
  'icon:sprout',
  'icon:heart',
  'icon:smile',
  'icon:coffee',
  'icon:book',
  'icon:house',
  'icon:star',
];

bool isAvatarIconId(String value) => avatarIconIds.contains(value);
