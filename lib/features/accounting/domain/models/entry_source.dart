/// Transaction entry-path provenance.
///
/// Values persist as TEXT in `transactions.entry_source` via [Enum.name].
/// Create-transaction callers stamp the source explicitly at the use-case
/// boundary. `ocr` is reserved for MOD-005; Phase 17 declares it but does not
/// stamp production rows with it.
///
/// Keep member order aligned with the SQL CHECK domain: manual, voice, ocr.
enum EntrySource { manual, voice, ocr }
