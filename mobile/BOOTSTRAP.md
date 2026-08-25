# Android bootstrap

The coding environment used to assemble this repository does not include the Flutter SDK, so the Android platform wrapper is intentionally not generated here.

On the Windows development machine:

```powershell
cd mobile
flutter create .
flutter pub get
flutter run --dart-define=ONEOPS_API=http://10.0.2.2:8787
```

If `flutter create .` rewrites `pubspec.yaml`, restore the repository `pubspec.yaml` from this folder and run `flutter pub get` again.

For a physical iQOO phone, use the laptop LAN IP instead of `10.0.2.2`:

```powershell
flutter run --dart-define=ONEOPS_API=http://192.168.x.x:8787
```

Make sure Windows Firewall allows TCP 8787 on the local/private network.
