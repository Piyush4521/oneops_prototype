# OneOps Mobile
Phone-first Flutter client for the OneOps prototype.

## Run
1. Install Flutter.
2. `flutter pub get`
3. Android emulator: `flutter run`
4. Physical phone: `flutter run --dart-define=ONEOPS_API=http://<LAPTOP-LAN-IP>:8787`

The UI is intentionally functional: it talks to the OneOps backend, captures camera evidence, starts voice input, displays the Incident Capsule, runs investigation/reproduction/verification and requires an explicit recovery approval.
