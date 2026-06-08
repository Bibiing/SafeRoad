@echo off
REM Jalankan SafeRoad dengan secrets yang diperlukan Firebase, ImageKit, dll.
REM Usage: run.bat             -> flutter run (debug)
REM        run.bat --release   -> flutter run --release
flutter run --dart-define-from-file=secrets.json %*
