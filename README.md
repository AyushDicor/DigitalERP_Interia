# newdigitalerp

A new Flutter project.

## Getting Started
how to build?(paste the code in terminal)o
1)Build Split APK (smaller size)
paste this ----------
flutter clean
flutter pub get
flutter build apk --split-per-abi


2)Release APK (for sharing / production)
paste this ---------
flutter clean
flutter pub get
flutter build apk --release

3)Debug APK (for testing)
paste this ------------
flutter clean
flutter pub get
flutter build apk --debug


how to push to GitHub ?
git commit -m "Initial commit"
git remote add origin
git branch -M main
git push -u origin main
