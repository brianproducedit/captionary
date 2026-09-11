
import glob

def remove_import(file_path, import_str):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    if import_str in content:
        content = content.replace(import_str, '')
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

remove_import('lib/screens/export_screen.dart', 'import \'../theme/app_gradients.dart\';\n')
remove_import('lib/screens/studio_screen.dart', 'import \'../theme/app_gradients.dart\';\n')
remove_import('lib/theme/app_shadows.dart', 'import \'app_colors.dart\';\n')

# Fix app_theme.dart
with open('lib/theme/app_theme.dart', 'r', encoding='utf-8') as f:
    app_theme = f.read()
if 'cardTheme: CardTheme(' in app_theme:
    app_theme = app_theme.replace('cardTheme: CardTheme(', 'cardTheme: const CardTheme(') # CardTheme usually takes same args as CardThemeData, wait, no it doesn't matter, CardTheme *is* a class, but ThemeData uses CardTheme, wait let me check the error.
with open('lib/theme/app_theme.dart', 'w', encoding='utf-8') as f:
    f.write(app_theme)

# Fix test/widget_test.dart
with open('test/widget_test.dart', 'r', encoding='utf-8') as f:
    test_content = f.read()
test_content = test_content.replace('MyApp()', 'const CaptionaryApp()')
with open('test/widget_test.dart', 'w', encoding='utf-8') as f:
    f.write(test_content)

