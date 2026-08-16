# API Coverage — Phase 59 Flutter platform-plugin surfaces

> Full coverage by default. This matrix enumerates the app-facing plugin capabilities that Phase 59 must preserve while deciding each existing package version. Opt-outs are explicit package-surface decisions, not silent omissions.

| capability | decision | reason |
|---|---|---|
| file_picker.custom_hpb_selection | INTEGRATE | |
| file_picker.cancel_or_missing_path_noop | INTEGRATE | |
| file_picker.multiple_file_selection | OPT-OUT | Backup restore intentionally accepts one encrypted .hpb file; multi-select is outside the existing product contract. |
| share_plus.encrypted_backup_file_share | INTEGRATE | |
| share_plus.family_invite_text_share | INTEGRATE | |
| share_plus.share_result_analytics | OPT-OUT | The app does not track share-target outcomes and Phase 59 must not add analytics or recipient disclosure. |
| package_info_plus.application_identity_and_version | INTEGRATE | |
| win32.transitive_solver_compatibility | INTEGRATE | |
| win32.direct_application_calls | OPT-OUT | win32 is an atomic transitive solver member; Happy Pocket has no direct Windows API call surface. |
| speech_to_text.initialize | INTEGRATE | |
| speech_to_text.status_callback | INTEGRATE | |
| speech_to_text.error_callback | INTEGRATE | |
| speech_to_text.available_locales | INTEGRATE | |
| speech_to_text.ja_recognition | INTEGRATE | |
| speech_to_text.zh_recognition | INTEGRATE | |
| speech_to_text.en_recognition | INTEGRATE | |
| speech_to_text.partial_results | INTEGRATE | |
| speech_to_text.sound_level | INTEGRATE | |
| speech_to_text.stop | INTEGRATE | |
| speech_to_text.cancel | INTEGRATE | |
| speech_to_text.cancel_before_restart | INTEGRATE | |
| speech_to_text.on_device_first | INTEGRATE | |
| speech_to_text.caller_allowed_default_recognition_fallback | INTEGRATE | |
| speech_to_text.caller_disallowed_network_fallback | INTEGRATE | |
| speech_to_text.continuous_background_dictation | OPT-OUT | The existing adapter supports bounded foreground voice entry and upstream is not used as a continuous/background recorder. |
| firebase_core.android_initialization | INTEGRATE | |
| firebase_core.ios_initialization | OPT-OUT | iOS intentionally uses the custom APNs client and passes no Firebase initializer. |
| firebase_messaging.android_permission_request | INTEGRATE | |
| firebase_messaging.android_token | INTEGRATE | |
| firebase_messaging.android_token_refresh | INTEGRATE | |
| firebase_messaging.foreground_message | INTEGRATE | |
| firebase_messaging.opened_app_message | INTEGRATE | |
| firebase_messaging.initial_message | INTEGRATE | |
| apns.ios_custom_transport | INTEGRATE | |
| flutter_local_notifications.initialize | INTEGRATE | |
| flutter_local_notifications.foreground_display | INTEGRATE | |
| flutter_local_notifications.tap_routing | INTEGRATE | |
| notifications.user_visible_settings | OPT-OUT | First-release notification settings remain intentionally hidden under ReleaseFeatures.pushNotifications false. |
| notifications.live_production_delivery_acceptance | OPT-OUT | Phase 59 preserves lifecycle through fakes and available native smoke; final production-identity/device acceptance belongs to the isolated Phase 63 lane. |
| local_auth.availability | INTEGRATE | |
| local_auth.biometric_only_authenticate | INTEGRATE | |
| local_auth.sensitive_transaction | INTEGRATE | |
| local_auth.persist_across_backgrounding | INTEGRATE | |
| local_auth.app_pin_fallback | INTEGRATE | |
| local_auth.os_device_passcode_fallback | OPT-OUT | App lock deliberately rejects OS passcode fallback and routes non-biometric outcomes to the app-owned PIN. |
| flutter_secure_storage.write | INTEGRATE | |
| flutter_secure_storage.read | INTEGRATE | |
| flutter_secure_storage.delete | INTEGRATE | |
| flutter_secure_storage.contains_key | INTEGRATE | |
| flutter_secure_storage.precise_clear_all | INTEGRATE | |
| flutter_secure_storage.clear_user_data_preserve_master_key | INTEGRATE | |
| flutter_secure_storage.typed_key_helpers | INTEGRATE | |
| flutter_secure_storage.unlocked_this_device_accessibility | INTEGRATE | |
| flutter_secure_storage.major_11_migration | OPT-OUT | Version 11 remains held until an explicit read-then-rewrite design and real pre-existing-key/device evidence exist. |
| app_initializer.master_key_before_database | INTEGRATE | |
| app_initializer.missing_key_with_existing_data_fail_closed | INTEGRATE | |
| image_picker.existing_image_selection | INTEGRATE | |
| path_provider.existing_app_private_paths | INTEGRATE | |
| url_launcher.existing_external_legal_support_launch | INTEGRATE | |
| connectivity_plus.existing_reachability_observation | INTEGRATE | |
| lucide_icons_flutter.static_font_subset | INTEGRATE | |
| lucide_icons_flutter.used_codepoint_contract | INTEGRATE | |
| lucide_icons_flutter.variable_weight_font_assets | OPT-OUT | The reviewed local fork intentionally excludes six unused variable-weight assets while preserving the used static font API. |
