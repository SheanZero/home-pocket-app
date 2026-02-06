import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/shared/utils/formatters/date_formatter.dart';
import 'package:home_pocket/shared/utils/formatters/number_formatter.dart';

/// Comprehensive test screen for MOD-014 Internationalization features
///
/// Demonstrates:
/// - Runtime locale switching
/// - Translation string display across all categories
/// - Date/time formatting in different locales
/// - Number and currency formatting
/// - Parameterized strings
class I18nTestScreen extends ConsumerWidget {
  const I18nTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context)!;
    final currentLocale = ref.watch(currentLocaleProvider);
    final localeNotifier = ref.read(localeNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.language} ${l10n.settings}'),
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Locale Switcher Section
          _buildSection(
            title: '1. Runtime Locale Switching',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Locale: ${currentLocale.languageCode}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                localeNotifier.setLocale(const Locale('ja')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  currentLocale.languageCode == 'ja'
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                            child: const Text('日本語'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                localeNotifier.setLocale(const Locale('en')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  currentLocale.languageCode == 'en'
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                            child: const Text('English'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                localeNotifier.setLocale(const Locale('zh')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  currentLocale.languageCode == 'zh'
                                      ? Colors.blue
                                      : Colors.grey,
                            ),
                            child: const Text('中文'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Core UI Translations
          _buildSection(
            title: '2. Core UI Translations',
            child: _buildTranslationCard(context, {
              'App Name': l10n.appName,
              'Home': l10n.home,
              'Transactions': l10n.transactions,
              'Analytics': l10n.analytics,
              'Settings': l10n.settings,
              'New Transaction': l10n.newTransaction,
              'Amount': l10n.amount,
              'Category': l10n.category,
              'Note': l10n.note,
              'Save': l10n.save,
              'Cancel': l10n.cancel,
              'Delete': l10n.delete,
              'Edit': l10n.edit,
              'Survival Ledger': l10n.survivalLedger,
              'Soul Ledger': l10n.soulLedger,
            }),
          ),

          // Navigation Menu Translations
          _buildSection(
            title: '3. Navigation Menu Translations',
            child: _buildTranslationCard(context, {
              'Dashboard': l10n.dashboard,
              'Reports': l10n.reports,
              'Sync': l10n.sync,
              'Backup': l10n.backup,
              'Security': l10n.security,
              'About': l10n.about,
              'Help': l10n.help,
              'Profile': l10n.profile,
              'Language': l10n.language,
              'Theme': l10n.theme,
              'Notifications': l10n.notifications,
              'Privacy': l10n.privacy,
              'Export': l10n.export,
              'Import': l10n.import,
              'Categories': l10n.categories,
            }),
          ),

          // Category Translations
          _buildSection(
            title: '4. Category Name Translations',
            child: _buildTranslationCard(context, {
              'Food': l10n.categoryFood,
              'Housing': l10n.categoryHousing,
              'Transport': l10n.categoryTransport,
              'Utilities': l10n.categoryUtilities,
              'Healthcare': l10n.categoryHealthcare,
              'Education': l10n.categoryEducation,
              'Clothing': l10n.categoryClothing,
              'Insurance': l10n.categoryInsurance,
              'Taxes': l10n.categoryTaxes,
              'Other': l10n.categoryOther,
              'Entertainment': l10n.categoryEntertainment,
              'Hobbies': l10n.categoryHobbies,
              'Self-Improvement': l10n.categorySelfImprovement,
              'Travel': l10n.categoryTravel,
              'Dining Out': l10n.categoryDining,
              'Cafe': l10n.categoryCafe,
              'Gifts': l10n.categoryGifts,
              'Beauty': l10n.categoryBeauty,
              'Fitness': l10n.categoryFitness,
              'Books': l10n.categoryBooks,
            }),
          ),

          // Error Messages
          _buildSection(
            title: '5. Error Messages',
            child: _buildTranslationCard(context, {
              'Network Error': l10n.errorNetwork,
              'Unknown Error': l10n.errorUnknown,
              'Invalid Amount': l10n.errorInvalidAmount,
              'Required Field': l10n.errorRequired,
              'Invalid Date': l10n.errorInvalidDate,
              'Database Write': l10n.errorDatabaseWrite,
              'Database Read': l10n.errorDatabaseRead,
              'Encryption Error': l10n.errorEncryption,
              'Sync Failed': l10n.errorSync,
              'Biometric Failed': l10n.errorBiometric,
              'Permission Denied': l10n.errorPermission,
            }),
          ),

          // Parameterized Strings
          _buildSection(
            title: '6. Parameterized Strings',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min Amount (0.01):',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(l10n.errorMinAmount(0.01)),
                    const Divider(height: 24),
                    Text(
                      'Max Amount (999999.99):',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(l10n.errorMaxAmount(999999.99)),
                  ],
                ),
              ),
            ),
          ),

          // UI Action Strings
          _buildSection(
            title: '7. UI Action Strings',
            child: _buildTranslationCard(context, {
              'Confirm': l10n.confirm,
              'Retry': l10n.retry,
              'Search': l10n.search,
              'Filter': l10n.filter,
              'Sort': l10n.sort,
              'Refresh': l10n.refresh,
              'Close': l10n.close,
              'OK': l10n.ok,
              'Yes': l10n.yes,
              'No': l10n.no,
              'Loading': l10n.loading,
              'No Data': l10n.noData,
            }),
          ),

          // Success Messages
          _buildSection(
            title: '8. Success Messages',
            child: _buildTranslationCard(context, {
              'Saved': l10n.successSaved,
              'Deleted': l10n.successDeleted,
              'Synced': l10n.successSynced,
            }),
          ),

          // Time Labels
          _buildSection(
            title: '9. Time Labels',
            child: _buildTranslationCard(context, {
              'Today': l10n.today,
              'Yesterday': l10n.yesterday,
            }),
          ),

          // Date Formatting
          _buildSection(
            title: '10. Date Formatting',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattingRow(
                      context,
                      'formatDate',
                      DateFormatter.formatDate(
                        DateTime(2026, 2, 4),
                        currentLocale,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'formatDateTime',
                      DateFormatter.formatDateTime(
                        DateTime(2026, 2, 4, 14, 30),
                        currentLocale,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'formatRelative (today)',
                      DateFormatter.formatRelative(
                        DateTime.now(),
                        currentLocale,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'formatRelative (yesterday)',
                      DateFormatter.formatRelative(
                        DateTime.now().subtract(const Duration(days: 1)),
                        currentLocale,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'formatMonthYear',
                      DateFormatter.formatMonthYear(
                        DateTime(2026, 2, 4),
                        currentLocale,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Number Formatting
          _buildSection(
            title: '11. Number Formatting',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattingRow(
                      context,
                      'Number (1234567.89)',
                      NumberFormatter.formatNumber(1234567.89, currentLocale),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'Percentage (0.1234)',
                      NumberFormatter.formatPercentage(0.1234, currentLocale),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'Compact (1234567)',
                      NumberFormatter.formatCompact(1234567, currentLocale),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Currency Formatting
          _buildSection(
            title: '12. Currency Formatting',
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattingRow(
                      context,
                      'JPY (1234.56)',
                      NumberFormatter.formatCurrency(
                        1234.56,
                        'JPY',
                        currentLocale,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'USD (1234.56)',
                      NumberFormatter.formatCurrency(
                        1234.56,
                        'USD',
                        currentLocale,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'CNY (1234.56)',
                      NumberFormatter.formatCurrency(
                        1234.56,
                        'CNY',
                        currentLocale,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'EUR (1234.56)',
                      NumberFormatter.formatCurrency(
                        1234.56,
                        'EUR',
                        currentLocale,
                      ),
                    ),
                    const Divider(height: 16),
                    _buildFormattingRow(
                      context,
                      'GBP (1234.56)',
                      NumberFormatter.formatCurrency(
                        1234.56,
                        'GBP',
                        currentLocale,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildTranslationCard(
    BuildContext context,
    Map<String, String> translations,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: translations.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      '${entry.key}:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFormattingRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }
}
