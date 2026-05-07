import sys

file_path = r'lib\core\providers\auth_provider.dart'

with open(file_path, 'r') as f:
    content = f.read()

stack = []
for i, char in enumerate(content):
    if char == '{':
        stack.append(i)
    elif char == '}':
        if not stack:
            print(f"Extra closing brace at char {i}")
        else:
            stack.pop()

if stack:
    print(f"Unclosed braces at indices: {stack}")
    for idx in stack:
        # Show some context around the unclosed brace
        start = max(0, idx - 20)
        end = min(len(content), idx + 20)
        print(f"Context: {content[start:end]}")
else:
    print("Braces are balanced.")
