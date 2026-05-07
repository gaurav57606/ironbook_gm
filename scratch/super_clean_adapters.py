import sys
import os

file_path = r'lib\core\data\local\adapters\manual_adapters.dart'

with open(file_path, 'r') as f:
    lines = f.readlines()

# TypeIds that should NOT have memberId
NO_MEMBER_ID_TYPES = {10, 2, 3, 4, 6, 5, 14, 13}

new_lines = []
current_type_id = None
current_class = None

for i, line in enumerate(lines):
    line_num = i + 1
    strip_line = line.strip()
    
    if strip_line.startswith('class ') and 'Adapter' in strip_line:
        current_class = strip_line
        current_type_id = None
    
    if 'final int typeId =' in strip_line:
        try:
            current_type_id = int(strip_line.split('=')[1].split(';')[0].strip())
        except:
            pass
            
    # Fix typos regardless of class
    if 'entityid:' in line:
        line = line.replace('entityid:', 'entityId:')
    if 'deviceid:' in line:
        line = line.replace('deviceid:', 'deviceId:')
    if 'planid:' in line:
        line = line.replace('planid:', 'planId:')
    if 'productid:' in line:
        line = line.replace('productid:', 'productId:')
    if 'memberid:' in line:
        line = line.replace('memberid:', 'memberId:')
    if 'selectedCharacterid:' in line:
        line = line.replace('selectedCharacterid:', 'selectedCharacterId:')
        
    # Remove memberId if current type shouldn't have it
    if current_type_id in NO_MEMBER_ID_TYPES:
        if 'memberId' in line:
            # Check if it's a field assignment or writer.write
            if 'memberId:' in line or 'writer.write(obj.memberId)' in line or 'final memberId =' in line:
                continue
            # Also handle the read() as String version without label
            if 'reader.read() as String' in line and i > 0:
                # Be careful not to remove valid fields.
                # In DomainEvent, we saw multiple reader.read() as String for memberId.
                # If the line is JUST reader.read() as String, it's risky unless we know it's a duplicate.
                # But here we see labeled ones mostly.
                if 'memberId:' in line:
                    continue

    # DomainEvent specific cleanup (it's very messy)
    if current_type_id == 10:
        if 'memberId: reader.read() as String,' in line:
            continue

    new_lines.append(line)

# Final pass to ensure no double empty lines or other artifacts
with open(file_path, 'w') as f:
    f.writelines(new_lines)
