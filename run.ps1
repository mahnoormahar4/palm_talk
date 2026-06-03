$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
cd android
.\gradlew.bat assembleDebug
cd ..
flutter install --use-application-binary android\app\build\outputs\flutter-apk\app-debug.apk
