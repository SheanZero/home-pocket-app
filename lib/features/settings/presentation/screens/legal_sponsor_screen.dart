import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../widgets/legal_sponsor_section.dart';

class LegalSponsorScreen extends StatelessWidget {
  const LegalSponsorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        centerTitle: true,
        title: Text(S.of(context).legalSponsorSectionTitle),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 28),
        child: LegalSponsorSection(showTitle: false),
      ),
    );
  }
}
