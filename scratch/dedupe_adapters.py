import sys
import os

file_path = r'lib\core\data\local\adapters\manual_adapters.dart'

with open(file_path, 'r') as f:
    lines = f.readlines()

new_lines = []
current_block = []
in_block = False

# We want to deduplicate identical lines within the same method/block
for i, line in enumerate(lines):
    strip_line = line.strip()
    
    if strip_line == '}':
        # End of class or method
        # If we were tracking a block, we'd process it. 
        # But let's just do it simpler: if the previous line is identical to this one and it's a reader.read() or writer.write()
        pass
        
    if i > 0:
        prev_line = lines[i-1]
        # Only deduplicate if it's a memberId read/write which is the main culprit
        if 'memberId' in line and line == prev_line:
            continue
            
    new_lines.append(line)

with open(file_path, 'w') as f:
    f.writelines(new_lines)
