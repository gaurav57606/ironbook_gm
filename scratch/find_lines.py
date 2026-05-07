file_path = r'lib\core\providers\auth_provider.dart'

with open(file_path, 'r') as f:
    content = f.read()

indices = [2460, 5131]
for idx in indices:
    line_num = content.count('\n', 0, idx) + 1
    print(f"Index {idx} is at line {line_num}")
