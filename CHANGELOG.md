## 0.1.0

* **Breaking:** Replaced `assets_audio_player` (abandoned) with `just_audio`.
* **Breaking:** `maxRecordTime` is now optional (defaults to `Duration.zero` for infinite recording).
* Added infinite recording support — use `Duration.zero` or omit `maxRecordTime`.
* Added `showMaxTime` parameter to show/hide max time in timer display (always hidden when infinite).
* Added `onRecordStart` callback — fires when recording begins.
* Added `onRecordDelete` callback — fires when a recording is deleted.
* Added `buttonSize` parameter to customize button size (default: `60`).
* Added `buttonColor` parameter to customize button fill color.
* Added `waveColor` parameter to customize amplitude wave ring color.
* Improved timer display: cleaner format (mm:ss), recording indicator, better typography.
* Fixed: `setState` missing in `_startRecord` — UI now updates immediately when recording starts.
* Fixed: Timer now correctly calls `setState` each tick so elapsed time updates the UI.
* Fixed: `withOpacity` deprecation — migrated to `withValues(alpha:)`.
* Removed debug `log()` calls from player.
* Updated README with Android/iOS permissions setup and full parameters table.

## 0.0.2

* Update flutter compatibility.
* Update button (FilledButton).
* Fix timer format.
* Upgraded dependencies.

## 0.0.1

* First release
