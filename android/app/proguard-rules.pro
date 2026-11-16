# Правила для оптимизатора R8 (работает только в release-сборке).
#
# R8 удаляет/переименовывает "неиспользуемый" код. Методы плагина
# shared_preferences вызываются из Dart через Pigeon, и R8 считает их
# лишними — без этого правила сохранение задач в release не работает
# (NoSuchMethodError: SharedPreferencesAsyncApiRegistrar.getString).
-keep class io.flutter.plugins.sharedpreferences.** { *; }
# Плагин обращается к классам Kotlin (Continuation, Result и др.) по их
# точным именам. Если R8 их переименует или удалит, вызов не найдёт их.
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
