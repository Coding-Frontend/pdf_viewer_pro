# Local Flutter SDK compatibility patch

Upstream package: pdfrx 1.3.5, unmodified pub.dev archive except the two
null assertions described below. Its original LICENSE is retained.

Archive: https://pub.dev/api/archives/pdfrx-1.3.5.tar.gz
SHA-256: 94c865686e7e15e93f2a5e3c0255f7d6c2ac39b2e5e82d62a0d278cb4b7d0d3b

Dart 3.13 no longer retains the nullable cache parameter's promotion across
the awaited download in the captured reader callback. The cache was already
initialized with `cache ??= ...` before this callback is created. Match the
existing `cache!` access earlier in the loop at the two later accesses.

This retains the existing viewer API, selection guard and native implementation.
Do not patch the global pub cache. Review this patch when upgrading pdfrx.
