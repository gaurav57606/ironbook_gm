import sys
import os

file_path = r'lib\core\data\local\adapters\manual_adapters.dart'

with open(file_path, 'r') as f:
    lines = f.readlines()

to_remove = [
    (209, 'memberId: reader.read() as String,'),
    (221, 'writer.write(obj.memberId);'),
    (238, 'memberId: reader.read() as String,'),
    (247, 'writer.write(obj.memberId);')
]

# Note: indices are 0-based in python, so 210 in 1-based is 209.
# We'll work backwards or filter by content in specific ranges.

new_lines = []
for i, line in enumerate(lines):
    line_num = i + 1
    strip_line = line.strip()
    
    # PlanAdapter (TypeId 2)
    if 205 <= line_num <= 230:
        if 'memberId' in line:
            continue
            
    # PlanComponentAdapter (TypeId 3)
    if 231 <= line_num <= 255:
        if 'memberId' in line:
            continue
            
    new_lines.append(line)

with open(file_path, 'w') as f:
    f.writelines(new_lines)
