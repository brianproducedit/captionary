
with open('lib/theme/app_theme.dart', 'r', encoding='utf-8') as f:
    app_theme = f.read()
if 'cardTheme: const CardTheme(' in app_theme:
    app_theme = app_theme.replace('cardTheme: const CardTheme(', 'cardTheme: const CardThemeData(')
with open('lib/theme/app_theme.dart', 'w', encoding='utf-8') as f:
    f.write(app_theme)

