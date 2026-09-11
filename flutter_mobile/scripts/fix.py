
import os
import glob

dart_files = glob.glob('lib/**/*.dart', recursive=True)
for file in dart_files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    changed = False
    
    if 'Theme.of(context).textTheme.captionCode' in content:
        content = content.replace('Theme.of(context).textTheme.captionCode', 'AppTypography.captionCode')
        if 'import \'../theme/app_typography.dart\';' not in content:
            lines = content.split('\n')
            last_import = max([i for i, l in enumerate(lines) if l.startswith('import ')], default=-1)
            if last_import != -1:
                lines.insert(last_import + 1, 'import \'../theme/app_typography.dart\';')
            content = '\n'.join(lines)
        changed = True
        
    if 'withOpacity' in content:
        content = content.replace('.withOpacity', '.withAlpha')
        changed = True

    if changed:
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)

