import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../../../../application/shopping_list/parse_shopping_voice_input_use_case.dart';
import '../../../../application/voice/repository_providers.dart'
    show appSpeechRecognitionServiceProvider;
import '../../../../application/voice/start_speech_recognition_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/constants/voice_tuning.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/ledger_type_selector.dart';
import '../../../../shared/widgets/list_type_selector.dart';
import '../../../accounting/domain/models/category.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider, deviceIdentityRepositoryProvider;
import '../../../accounting/presentation/screens/category_selection_screen.dart';
import '../../../accounting/presentation/utils/category_display_utils.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../../settings/presentation/providers/state_settings.dart';
import '../../../settings/presentation/utils/voice_locale_helpers.dart';
// isGroupModeProvider import removed — selector no longer gated on group mode (G8Z)
import '../../domain/models/shopping_item.dart';
import '../providers/repository_providers.dart'
    show createShoppingItemUseCaseProvider, updateShoppingItemUseCaseProvider;
import '../widgets/shopping_voice_draft_panel.dart';
import '../../../../application/shopping_list/create_shopping_item_use_case.dart';
import '../../../../application/shopping_list/update_shopping_item_use_case.dart';

/// Full-screen add/edit form for a shopping list item.
///
/// - Create mode: [item] is null; calls [CreateShoppingItemUseCase].
///   Default ledger: [LedgerType.daily] (always non-null; cannot toggle to null).
///   Default list type: 'public' (user may switch to 'private' via selector).
/// - Edit mode: [item] is non-null; pre-populates all fields; calls [UpdateShoppingItemUseCase].
/// - List-type selector (public/private) shown in ALL modes:
///   interactive in create mode, read-only in edit mode — reflects stored [listType]
///   and cannot be changed (D37-04/SYNC-03 immutability; the update path never alters it).
///   Placed AFTER the ledger selector (order: name → ledger → list-type → category → ...).
///   Always shown regardless of group membership (G8Z).
/// - Tags field is hidden from UI (D-2); edit mode transparently passes original item.tags.
/// - Note field is passed as plaintext; encryption is applied at the repository
///   boundary (Phase 36). Do NOT add encryption code here.
class ShoppingItemFormScreen extends ConsumerStatefulWidget {
  const ShoppingItemFormScreen({
    super.key,
    required this.listType,
    this.item,
    this.speechService,
  });

  /// 'public' or 'private' — immutable after creation (D6).
  final String listType;

  /// null = create mode; non-null = edit mode (ITEM-04).
  final ShoppingItem? item;

  /// Injectable speech boundary for deterministic widget tests.
  ///
  /// Production creates the same application-layer use case from the existing
  /// speech provider. Edit mode never initializes or renders voice input.
  final StartSpeechRecognitionUseCase? speechService;

  @override
  ConsumerState<ShoppingItemFormScreen> createState() =>
      _ShoppingItemFormScreenState();
}

class _ShoppingItemFormScreenState extends ConsumerState<ShoppingItemFormScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _showNameError = false;

  late final TextEditingController _nameController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  // Tags controller: holds original value but NOT rendered in UI (D-2).
  // Edit mode: used to hold item.tags for transparency; save uses widget.item!.tags directly.
  // Create mode: not used in save path.
  late final TextEditingController _tagsController;

  // Non-null LedgerType — defaults to daily; cannot be toggled to null (D-1).
  LedgerType _ledgerType = LedgerType.daily;
  String? _categoryId;
  // Target list for a NEW item ('private' | 'public'). Mutable only in create
  // mode via selector; immutable in edit mode (D6/SYNC-03).
  late String _listType;
  // Selected category + its parent, so the form can render the full
  // "parent > child" path via formatCategoryPath (mirrors transaction_details_form).
  // The model stores only categoryId, so both are loaded async in edit mode.
  Category? _category;
  Category? _parentCategory;

  ShoppingVoiceDraftState _voiceState = ShoppingVoiceDraftState.manual;
  StartSpeechRecognitionUseCase? _speechService;
  _ShoppingFormSnapshot? _voiceSnapshot;
  String _voiceTranscript = '';
  String _voiceLocaleId = 'ja-JP';
  double _voiceSoundLevel = 0;
  int _voiceGeneration = 0;
  int? _activeSpeechGeneration;
  bool _voiceOpening = false;
  bool _speechInitialized = false;

  // Focus node for the name field; autofocus only in create mode (D-4).
  late final FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listType = widget.listType;
    _nameFocusNode = FocusNode(debugLabel: 'shoppingNameFocus');

    final item = widget.item;
    if (item != null) {
      // Edit mode — pre-populate from existing item (ITEM-04)
      _nameController = TextEditingController(text: item.name);
      _quantityController = TextEditingController(
        text: item.quantity.toString(),
      );
      _priceController = TextEditingController(
        text: item.estimatedPrice?.toString() ?? '',
      );
      _noteController = TextEditingController(text: item.note ?? '');
      _tagsController = TextEditingController(text: item.tags.join(', '));
      // If item.ledgerType is null, display as daily (D-1).
      _ledgerType = item.ledgerType ?? LedgerType.daily;
      _categoryId = item.categoryId;
      if (item.categoryId != null) {
        _loadCategory(item.categoryId!);
      }
    } else {
      // Create mode — quantity defaults to '1' (D-3); daily ledger pre-selected (D-1).
      _ledgerType = LedgerType.daily;
      _nameController = TextEditingController();
      _quantityController = TextEditingController(text: '1');
      _priceController = TextEditingController();
      _noteController = TextEditingController();
      _tagsController = TextEditingController();
      // Autofocus name field in create mode (D-4).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nameFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeSpeechGeneration = null;
    _voiceGeneration++;
    final speechService = _speechService;
    if (speechService != null) unawaited(speechService.cancel());
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_isVoiceTransient) unawaited(_returnToKeyboard());
    }
  }

  bool get _isVoiceTransient =>
      _voiceOpening ||
      _voiceState == ShoppingVoiceDraftState.listening ||
      _voiceState == ShoppingVoiceDraftState.processing;

  bool _isCurrentVoiceGeneration(int generation) =>
      mounted && generation == _voiceGeneration;

  _ShoppingFormSnapshot _captureVoiceSnapshot() => _ShoppingFormSnapshot(
    name: _nameController.text,
    quantity: _quantityController.text,
    price: _priceController.text,
    note: _noteController.text,
    ledgerType: _ledgerType,
    categoryId: _categoryId,
    category: _category,
    parentCategory: _parentCategory,
  );

  void _restoreVoiceSnapshot(_ShoppingFormSnapshot snapshot) {
    _nameController.text = snapshot.name;
    _quantityController.text = snapshot.quantity;
    _priceController.text = snapshot.price;
    _noteController.text = snapshot.note;
    _ledgerType = snapshot.ledgerType;
    _categoryId = snapshot.categoryId;
    _category = snapshot.category;
    _parentCategory = snapshot.parentCategory;
  }

  Future<void> _openVoiceDraft() async {
    if (widget.item != null ||
        _voiceState != ShoppingVoiceDraftState.manual ||
        _voiceOpening) {
      return;
    }
    FocusScope.of(context).unfocus();
    _voiceSnapshot = _captureVoiceSnapshot();
    _voiceTranscript = '';
    _voiceSoundLevel = 0;
    setState(() => _voiceOpening = true);
    final generation = ++_voiceGeneration;
    final locale =
        ref.read(currentLocaleProvider).value ??
        Localizations.localeOf(context);
    _voiceLocaleId =
        ref.read(voiceLocaleIdProvider).value ??
        voiceLocaleIdFromLanguageCode(locale.languageCode);
    final speechService = _speechService ??=
        widget.speechService ??
        StartSpeechRecognitionUseCase(
          service: ref.read(appSpeechRecognitionServiceProvider),
        );

    try {
      final available =
          _speechInitialized ||
          await speechService.initialize(
            onStatus: _handleActiveVoiceStatus,
            onError: _handleActiveVoiceError,
          );
      if (!_isCurrentVoiceGeneration(generation) ||
          _voiceState == ShoppingVoiceDraftState.unavailable) {
        return;
      }
      _voiceOpening = false;
      if (!available) {
        _markVoiceUnavailable(generation);
        return;
      }
      _speechInitialized = true;
      setState(() {
        _showNameError = false;
        _voiceState = ShoppingVoiceDraftState.listening;
      });
      await _startVoiceListening(generation);
    } catch (_) {
      _markVoiceUnavailable(generation);
    }
  }

  Future<void> _startVoiceListening(int generation) async {
    final speechService = _speechService;
    if (speechService == null || !_isCurrentVoiceGeneration(generation)) return;
    _activeSpeechGeneration = generation;
    try {
      await speechService.startListening(
        onResult: (result) => _handleVoiceResult(generation, result),
        onSoundLevel: (level) {
          if (!_isCurrentVoiceGeneration(generation) ||
              _voiceState != ShoppingVoiceDraftState.listening) {
            return;
          }
          setState(() => _voiceSoundLevel = level.clamp(0.0, 1.0));
        },
        localeId: _voiceLocaleId,
        listenFor: VoiceTuning.listenFor,
        pauseFor: const Duration(seconds: 3),
        allowOnDeviceFallback:
            ref.read(appSettingsProvider).value?.voiceAllowOnDeviceFallback ??
            true,
      );
    } catch (_) {
      _handleVoiceError(generation, permanent: false);
    }
  }

  void _handleActiveVoiceStatus(String status) {
    final generation = _activeSpeechGeneration;
    if (generation == null) return;
    _handleVoiceStatus(generation, status);
  }

  void _handleActiveVoiceError(String _, bool permanent) {
    final generation = _activeSpeechGeneration;
    if (generation == null) return;
    _handleVoiceError(generation, permanent: permanent);
  }

  void _handleVoiceStatus(int generation, String status) {
    if (!_isCurrentVoiceGeneration(generation) ||
        _voiceState != ShoppingVoiceDraftState.listening) {
      return;
    }
    final normalized = status.toLowerCase();
    if (normalized == 'done' || normalized == 'notlistening') {
      unawaited(_finishVoiceDraft(generation));
    }
  }

  void _handleVoiceResult(int generation, SpeechRecognitionResult result) {
    if (!_isCurrentVoiceGeneration(generation) || !_isVoiceTransient) return;
    final recognizedText = result.recognizedWords.trim();
    if (recognizedText.isNotEmpty) {
      setState(() => _voiceTranscript = recognizedText);
    }
    if (result.finalResult &&
        _voiceState == ShoppingVoiceDraftState.listening) {
      unawaited(_finishVoiceDraft(generation));
    }
  }

  Future<void> _finishVoiceDraft(int generation) async {
    if (!_isCurrentVoiceGeneration(generation) ||
        _voiceState != ShoppingVoiceDraftState.listening) {
      return;
    }
    _activeSpeechGeneration = null;
    setState(() {
      _voiceState = ShoppingVoiceDraftState.processing;
      _voiceSoundLevel = 0;
    });
    try {
      await _speechService?.stop();
    } catch (_) {
      _handleVoiceError(generation, permanent: false);
      return;
    }
    if (!_isCurrentVoiceGeneration(generation) ||
        _voiceState != ShoppingVoiceDraftState.processing) {
      return;
    }
    await _parseAndApplyVoiceDraft(generation);
  }

  Future<void> _parseAndApplyVoiceDraft(int generation) async {
    final draft = const ParseShoppingVoiceInputUseCase().execute(
      _voiceTranscript,
      localeId: _voiceLocaleId,
    );
    Category? resolvedCategory;
    Category? resolvedParent;
    final parsedCategoryId = draft.categoryId;
    if (parsedCategoryId != null) {
      try {
        resolvedCategory = await ref
            .read(categoryRepositoryProvider)
            .findById(parsedCategoryId);
        if (!_isCurrentVoiceGeneration(generation)) return;
        if (resolvedCategory != null) {
          resolvedParent = await _resolveParent(resolvedCategory);
          if (!_isCurrentVoiceGeneration(generation)) return;
        }
      } catch (_) {
        if (!_isCurrentVoiceGeneration(generation)) return;
        resolvedCategory = null;
        resolvedParent = null;
      }
    }
    if (!_isCurrentVoiceGeneration(generation) ||
        _voiceState != ShoppingVoiceDraftState.processing) {
      return;
    }

    setState(() {
      final parsedName = draft.name;
      if (parsedName != null) {
        _nameController.text = parsedName.length > 200
            ? parsedName.substring(0, 200)
            : parsedName;
        _showNameError = false;
      }
      final parsedQuantity = draft.quantity;
      if (parsedQuantity != null && parsedQuantity > 0) {
        _quantityController.text = parsedQuantity.toString();
      }
      final parsedLedger = draft.ledgerType;
      if (parsedLedger != null) _ledgerType = parsedLedger;
      if (resolvedCategory != null) {
        _categoryId = resolvedCategory.id;
        _category = resolvedCategory;
        _parentCategory = resolvedParent;
      }
      final parsedPrice = draft.estimatedPrice;
      if (parsedPrice != null && parsedPrice >= 0) {
        _priceController.text = parsedPrice.toString();
      }
      // listType is deliberately absent: voice is draft fill only and must
      // never infer public/private scope or persist the item automatically.
      _voiceState = ShoppingVoiceDraftState.review;
      _voiceSoundLevel = 0;
    });
  }

  Future<void> _returnToKeyboard() async {
    if (_voiceState == ShoppingVoiceDraftState.manual &&
        (!_voiceOpening || _voiceSnapshot == null)) {
      return;
    }
    final shouldRestore = _isVoiceTransient;
    final snapshot = _voiceSnapshot;
    final generation = ++_voiceGeneration;
    _activeSpeechGeneration = null;
    _voiceOpening = true;
    final speechService = _speechService;
    if (mounted) {
      setState(() {
        if (shouldRestore && snapshot != null) _restoreVoiceSnapshot(snapshot);
        _voiceState = ShoppingVoiceDraftState.manual;
        _voiceTranscript = '';
        _voiceSoundLevel = 0;
        _voiceSnapshot = null;
      });
    }
    try {
      await speechService?.cancel();
    } catch (_) {
      // The session token was invalidated before cancellation, so callbacks
      // from this stale session cannot update the form.
    }
    if (_isCurrentVoiceGeneration(generation)) {
      setState(() => _voiceOpening = false);
    }
  }

  Future<void> _rerecordVoiceDraft() async {
    if (_voiceState != ShoppingVoiceDraftState.review || _voiceOpening) return;
    final snapshot = _voiceSnapshot;
    final generation = ++_voiceGeneration;
    _activeSpeechGeneration = null;
    setState(() => _voiceOpening = true);
    try {
      await _speechService?.cancel();
    } catch (_) {
      // Starting the new generation below is still safe; stale callbacks from
      // the prior generation cannot pass the generation guard.
    }
    if (!_isCurrentVoiceGeneration(generation)) return;
    _voiceOpening = false;
    setState(() {
      if (snapshot != null) _restoreVoiceSnapshot(snapshot);
      _voiceState = ShoppingVoiceDraftState.listening;
      _voiceTranscript = '';
      _voiceSoundLevel = 0;
    });
    await _startVoiceListening(generation);
  }

  void _handleVoiceError(int generation, {required bool permanent}) {
    if (!_isCurrentVoiceGeneration(generation)) return;
    _activeSpeechGeneration = null;
    if (permanent) {
      _markVoiceUnavailable(generation);
      return;
    }
    final snapshot = _voiceSnapshot;
    _voiceGeneration++;
    _voiceOpening = false;
    final speechService = _speechService;
    if (speechService != null) unawaited(speechService.cancel());
    if (!mounted) return;
    setState(() {
      if (snapshot != null) _restoreVoiceSnapshot(snapshot);
      _voiceState = ShoppingVoiceDraftState.manual;
      _voiceTranscript = '';
      _voiceSoundLevel = 0;
      _voiceSnapshot = null;
    });
    showErrorFeedback(context, S.of(context).voiceRecognitionErrorUnknown);
  }

  void _markVoiceUnavailable(int generation) {
    if (!_isCurrentVoiceGeneration(generation)) return;
    _activeSpeechGeneration = null;
    _voiceGeneration++;
    _voiceOpening = false;
    final speechService = _speechService;
    if (speechService != null) unawaited(speechService.cancel());
    if (!mounted) return;
    setState(() {
      _voiceState = ShoppingVoiceDraftState.unavailable;
      _voiceTranscript = '';
      _voiceSoundLevel = 0;
    });
  }

  void _showVoiceSettingsGuidance() {
    showErrorFeedback(context, S.of(context).voiceMicrophonePermissionRequired);
  }

  Future<void> _save() async {
    if (_isSubmitting || _isVoiceTransient) return;
    if (_nameController.text.trim().isEmpty) {
      if (!_showNameError) setState(() => _showNameError = true);
      return;
    }

    setState(() {
      _showNameError = false;
      _isSubmitting = true;
    });

    // Sanitize numeric inputs (WR-03): quantity is at least 1; a negative or
    // zero entry falls back to 1. Estimated price must be non-negative; a
    // negative entry is treated as "not provided".
    final parsedQuantity = int.tryParse(_quantityController.text);
    final quantity = (parsedQuantity == null || parsedQuantity < 1)
        ? 1
        : parsedQuantity;
    final parsedPrice = int.tryParse(_priceController.text);
    final estimatedPrice = (parsedPrice == null || parsedPrice < 0)
        ? null
        : parsedPrice;

    try {
      if (widget.item == null) {
        // Create mode — obtain deviceId from device identity repository
        final deviceId =
            await ref.read(deviceIdentityRepositoryProvider).getDeviceId() ??
            '';
        final params = CreateShoppingItemParams(
          deviceId: deviceId,
          listType: _listType,
          name: _nameController.text.trim(),
          ledgerType: _ledgerType,
          categoryId: _categoryId,
          tags: const [],
          note: _noteController.text.isEmpty ? null : _noteController.text,
          quantity: quantity,
          estimatedPrice: estimatedPrice,
        );
        final result = await ref
            .read(createShoppingItemUseCaseProvider)
            .execute(params);
        if (result.isError) throw Exception(result.error);
      } else {
        // Edit mode — update existing item (ITEM-04).
        // Tags are passed through directly from the original item (D-2).
        final params = UpdateShoppingItemParams(
          itemId: widget.item!.id,
          name: _nameController.text.trim(),
          ledgerType: _ledgerType,
          categoryId: _categoryId,
          tags: widget.item!.tags,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          quantity: quantity,
          estimatedPrice: estimatedPrice,
        );
        final result = await ref
            .read(updateShoppingItemUseCaseProvider)
            .execute(params);
        if (result.isError) throw Exception(result.error);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showErrorFeedback(context, S.of(context).shoppingFormSaveError);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickCategory() async {
    final selected = await Navigator.push<Category>(
      context,
      MaterialPageRoute<Category>(
        builder: (_) =>
            CategorySelectionScreen(selectedCategoryId: _categoryId),
      ),
    );
    if (selected == null || !mounted) return;
    final parent = await _resolveParent(selected);
    if (!mounted) return;
    setState(() {
      _categoryId = selected.id;
      _category = selected;
      _parentCategory = parent;
    });
  }

  /// Loads the category AND its parent from a stored id (edit-mode
  /// pre-population), so the form can render the full "parent > child" path
  /// at build time via [formatCategoryPath] (CR-01; mirrors transaction form).
  Future<void> _loadCategory(String categoryId) async {
    final category = await ref
        .read(categoryRepositoryProvider)
        .findById(categoryId);
    if (category == null || !mounted) return;
    final parent = await _resolveParent(category);
    if (!mounted) return;
    setState(() {
      _category = category;
      _parentCategory = parent;
    });
  }

  /// Fetches the parent category for an L2 category (null for L1 / orphaned).
  Future<Category?> _resolveParent(Category category) async {
    final parentId = category.parentId;
    if (category.level == 1 || parentId == null) return null;
    return ref.read(categoryRepositoryProvider).findById(parentId);
  }

  Widget _buildSaveButton(S l) {
    final palette = context.palette;
    final enabled = !_isSubmitting && !_isVoiceTransient;
    final actionLabel = _isSubmitting
        ? l.shoppingFormSaving
        : l.shoppingFormSave;
    return Semantics(
      button: true,
      enabled: enabled,
      label: actionLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.46,
        child: SizedBox(
          key: const Key('shopping_form_save_button'),
          width: 72,
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.accentPrimary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: palette.accentPrimary.withValues(alpha: 0.2),
                        blurRadius: 13,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: enabled ? _save : null,
                child: Center(
                  child: Text(
                    actionLabel,
                    style: AppTextStyles.button.copyWith(color: palette.card),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper(S l) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: palette.borderDefault),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _stepBtn(
              key: const Key('shopping_quantity_decrease'),
              label: '−',
              semanticLabel: '${l.shoppingFormQuantityLabel} −',
              onTap: () {
                final value = int.tryParse(_quantityController.text) ?? 1;
                if (value > 1) {
                  setState(
                    () => _quantityController.text = (value - 1).toString(),
                  );
                }
              },
              palette: palette,
            ),
            SizedBox(
              width: 50,
              height: 44,
              child: TextField(
                key: const Key('shopping_form_quantity_field'),
                controller: _quantityController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                style: AppTextStyles.itemTitle.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed < 1) {
                    setState(() => _quantityController.text = '1');
                  }
                },
              ),
            ),
            _stepBtn(
              key: const Key('shopping_quantity_increase'),
              label: '＋',
              semanticLabel: '${l.shoppingFormQuantityLabel} ＋',
              onTap: () {
                final value = int.tryParse(_quantityController.text) ?? 1;
                setState(
                  () => _quantityController.text = (value + 1).toString(),
                );
              },
              palette: palette,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn({
    required Key key,
    required String label,
    required String semanticLabel,
    required VoidCallback onTap,
    required AppPalette palette,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox.square(
        key: key,
        dimension: 44,
        child: Material(
          color: palette.backgroundMuted,
          child: InkWell(
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.amountMedium.copyWith(
                  color: palette.dailyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(height: 1, color: palette.backgroundDivider),
    );
  }

  BoxDecoration _cardDecoration(AppPalette palette) => BoxDecoration(
    color: palette.card,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: palette.borderDefault),
    boxShadow: [
      BoxShadow(
        color: palette.navShadow,
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );

  ShoppingVoiceDraftCopy _voiceCopy(S l) => ShoppingVoiceDraftCopy(
    manualTitle: l.shoppingVoiceManualTitle,
    manualHelp: l.shoppingVoiceManualHelp,
    manualSemanticLabel: l.shoppingVoiceManualTitle,
    privacyLabel: l.shoppingVoicePrivacy,
    listeningStatus: l.shoppingVoiceListeningStatus,
    processingStatus: l.shoppingVoiceProcessingStatus,
    reviewStatus: l.shoppingVoiceReviewStatus,
    unavailableStatus: l.shoppingVoiceUnavailableStatus,
    keyboardSemanticLabel: l.shoppingVoiceKeyboardAction,
    listeningTranscriptPlaceholder: l.shoppingVoiceListeningPlaceholder,
    processingTranscriptPlaceholder: l.shoppingVoiceProcessingPlaceholder,
    reviewTranscriptPlaceholder: l.shoppingVoiceReviewPlaceholder,
    unavailableTranscript: l.voiceMicrophonePermissionRequired,
    stopSemanticLabel: l.shoppingVoiceStopAction,
    processingSemanticLabel: l.shoppingVoiceProcessingStatus,
    rerecordSemanticLabel: l.shoppingVoiceRerecordAction,
    unavailableCoreSemanticLabel: l.voiceMicrophonePermissionRequired,
    listeningHelp: l.shoppingVoiceListeningHelp,
    processingHelp: l.shoppingVoiceProcessingHelp,
    reviewHelp: l.shoppingVoiceReviewHelp,
    unavailableHelp: l.shoppingVoiceUnavailableHelp,
    settingsLabel: l.shoppingVoiceSettingsAction,
    settingsSemanticLabel: l.shoppingVoiceSettingsAction,
  );

  @override
  Widget build(BuildContext context) {
    final l = S.of(context);
    final palette = context.palette;
    final isEditMode = widget.item != null;
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    // Render the full "parent > child" localized path at build time (mirrors
    // transaction_details_form — never render the raw key/id).
    final categoryDisplay = _category == null
        ? null
        : formatCategoryPath(
            category: _category!,
            parentCategory: _parentCategory,
            locale: locale,
          );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 52,
        titleSpacing: 4,
        leading: IconButton(
          key: const Key('shopping_form_back_button'),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          isEditMode ? l.shoppingFormEditTitle : l.shoppingFormAddTitle,
          style: AppTextStyles.pageTitle.copyWith(color: palette.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildSaveButton(l),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            Container(
              key: const Key('shopping_form_name_card'),
              height: 58,
              decoration: _cardDecoration(palette).copyWith(
                border: Border.all(
                  color: _showNameError ? palette.error : palette.borderDefault,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              child: TextFormField(
                key: const Key('shopping_form_name_field'),
                controller: _nameController,
                focusNode: _nameFocusNode,
                autofocus: !isEditMode,
                maxLength: 200,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  hintText: l.shoppingFormNameLabel,
                  hintStyle: AppTextStyles.amountMedium.copyWith(
                    color: palette.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: AppTextStyles.amountMedium.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  if (_showNameError && value.trim().isNotEmpty) {
                    setState(() => _showNameError = false);
                  }
                },
              ),
            ),
            SizedBox(
              key: const Key('shopping_form_name_error_slot'),
              height: 22,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(3, 4, 3, 0),
                child: Semantics(
                  liveRegion: _showNameError,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      _showNameError ? l.shoppingFormNameRequired : '',
                      style: AppTextStyles.supporting.copyWith(
                        color: palette.error,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isEditMode) ...[
              const SizedBox(height: 10),
              ShoppingVoiceDraftPanel(
                state: _voiceState,
                copy: _voiceCopy(l),
                transcript: _voiceTranscript,
                soundLevel: _voiceSoundLevel,
                onOpen: () => unawaited(_openVoiceDraft()),
                onStop: () => unawaited(_finishVoiceDraft(_voiceGeneration)),
                onKeyboard: () => unawaited(_returnToKeyboard()),
                onRerecord: () => unawaited(_rerecordVoiceDraft()),
                onSettings: _showVoiceSettingsGuidance,
              ),
            ],
            const SizedBox(height: 14),
            Container(
              key: const Key('shopping_form_primary_card'),
              decoration: _cardDecoration(palette),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      children: [
                        Text(
                          l.shoppingFormQuantityLabel,
                          style: AppTextStyles.label.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        _buildStepper(l),
                      ],
                    ),
                  ),
                  _divider(palette),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Text(
                          l.expenseClassification,
                          style: AppTextStyles.label.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        LedgerTypeSelector(
                          key: const Key('shopping_form_ledger_selector'),
                          selected: _ledgerType,
                          onChanged: (type) =>
                              setState(() => _ledgerType = type),
                          dailyLabel: l.shoppingFormLedgerDaily,
                          joyLabel: l.shoppingFormLedgerJoy,
                          showIcons: false,
                          chipMinHeight: 44,
                          chipMinWidth: 84,
                        ),
                      ],
                    ),
                  ),
                  _divider(palette),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                    child: Row(
                      children: [
                        Text(
                          l.shoppingFormListTypeLabel,
                          style: AppTextStyles.label.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        ListTypeSelector(
                          key: const Key('shopping_form_list_type_selector'),
                          selected: _listType == 'public'
                              ? 'public'
                              : 'private',
                          onChanged: (value) =>
                              setState(() => _listType = value),
                          publicLabel: l.shoppingSegmentPublic,
                          privateLabel: l.shoppingSegmentPrivate,
                          enabled: !isEditMode,
                          showIcons: false,
                          chipMinHeight: 40,
                          chipMinWidth: 84,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    key: const Key('shopping_form_list_type_hint'),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          isEditMode ? Icons.lock_outline : Icons.info_outline,
                          size: 15,
                          color: isEditMode
                              ? palette.error
                              : palette.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isEditMode
                                ? l.shoppingListTypeLockedHint
                                : l.shoppingListTypeCreateHint,
                            textAlign: TextAlign.end,
                            style: AppTextStyles.supporting.copyWith(
                              color: isEditMode
                                  ? palette.error
                                  : palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              key: const Key('shopping_form_secondary_card'),
              decoration: _cardDecoration(palette),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _pickCategory,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 62),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Text(
                              l.shoppingFormCategoryLabel,
                              style: AppTextStyles.label.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                categoryDisplay ??
                                    l.shoppingFormNoCategorySelected,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: AppTextStyles.label.copyWith(
                                  color: categoryDisplay != null
                                      ? palette.textPrimary
                                      : palette.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 19,
                              color: palette.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _divider(palette),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 62),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Text(
                            l.shoppingFormPrice,
                            style: AppTextStyles.label.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '¥',
                            style: AppTextStyles.itemTitle.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              key: const Key('shopping_form_price_field'),
                              controller: _priceController,
                              textAlign: TextAlign.right,
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.itemTitle.copyWith(
                                color: palette.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                                hintText: l.shoppingFormPricePlaceholder,
                                hintStyle: AppTextStyles.itemTitle.copyWith(
                                  color: palette.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onSubmitted: (_) => unawaited(_save()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _divider(palette),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 24, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: 63,
                            child: Text(
                              l.shoppingFormNoteLabel,
                              style: AppTextStyles.label.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            key: const Key('shopping_form_note_field'),
                            controller: _noteController,
                            minLines: 3,
                            maxLines: 5,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: l.shoppingFormNotePlaceholder,
                              hintStyle: AppTextStyles.label.copyWith(
                                color: palette.textTertiary,
                              ),
                              filled: true,
                              fillColor: palette.backgroundMuted,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 9,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@immutable
class _ShoppingFormSnapshot {
  const _ShoppingFormSnapshot({
    required this.name,
    required this.quantity,
    required this.price,
    required this.note,
    required this.ledgerType,
    required this.categoryId,
    required this.category,
    required this.parentCategory,
  });

  final String name;
  final String quantity;
  final String price;
  final String note;
  final LedgerType ledgerType;
  final String? categoryId;
  final Category? category;
  final Category? parentCategory;
}
