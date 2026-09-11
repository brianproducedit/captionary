
import glob
import re

dart_files = glob.glob('lib/**/*.dart', recursive=True)
for file in dart_files:
    with open(file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if '.withAlpha' in content:
        # We need to change .withAlpha(0.X) back to .withValues(alpha: 0.X)
        # Using a regex to find .withAlpha(value)
        content = re.sub(r'\.withAlpha\(([^)]+)\)', r'.withValues(alpha: \1)', content)
        with open(file, 'w', encoding='utf-8') as f:
            f.write(content)

