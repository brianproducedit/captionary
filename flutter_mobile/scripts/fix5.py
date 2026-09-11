
import re
with open('lib/theme/app_theme.dart', 'r', encoding='utf-8') as f:
    app_theme = f.read()
app_theme = app_theme.replace('cardTheme: const CardThemeData(', 'cardTheme: const CardTheme(')
with open('lib/theme/app_theme.dart', 'w', encoding='utf-8') as f:
    f.write(app_theme)

with open('lib/widgets/status_chip.dart', 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace('Theme.of(context).textTheme.captionCode', 'AppTypography.captionCode')
if 'import \'../theme/app_typography.dart\';' not in content:
    lines = content.split('\n')
    last_import = max([i for i, l in enumerate(lines) if l.startswith('import ')], default=-1)
    if last_import != -1:
        lines.insert(last_import + 1, 'import \'../theme/app_typography.dart\';')
    content = '\n'.join(lines)
with open('lib/widgets/status_chip.dart', 'w', encoding='utf-8') as f:
    f.write(content)

