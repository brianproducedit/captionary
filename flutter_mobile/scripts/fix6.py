
import glob
import re

dart_files = glob.glob('lib/**/*.dart', recursive=True)
for file in dart_files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    changed = False
    if 'AppTypography.captionCode?.' in content:
        content = content.replace('AppTypography.captionCode?.', 'AppTypography.captionCode.')
        changed = True
        
    if changed:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)

with open('lib/theme/app_theme.dart', 'r', encoding='utf-8') as f:
    app_theme = f.read()
app_theme = app_theme.replace('cardTheme: const CardTheme(', 'cardTheme: CardTheme(')
app_theme = app_theme.replace('borderRadius: BorderRadius.circular(AppRadius.defaultRadius)', 'borderRadius: const BorderRadius.all(Radius.circular(AppRadius.defaultRadius))')
with open('lib/theme/app_theme.dart', 'w', encoding='utf-8') as f:
    f.write(app_theme)


