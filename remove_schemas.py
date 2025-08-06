#!/usr/bin/env python3

import re

# Read the OpenAPI file
with open('libs/api-client-go/api/openapi.yaml', 'r') as f:
    lines = f.readlines()

# Find and remove ComputerUse schema blocks
new_lines = []
skip_until_next_schema = False
current_indent = 0

for i, line in enumerate(lines):
    if 'ComputerUseStartResponse:' in line or 'ComputerUseStopResponse:' in line or 'ComputerUseStatusResponse:' in line:
        skip_until_next_schema = True
        current_indent = len(line) - len(line.lstrip())
        continue
    
    if skip_until_next_schema:
        line_indent = len(line) - len(line.lstrip())
        # If we find a line with same or less indentation that looks like a new schema, stop skipping
        if line_indent <= current_indent and line.strip() and ':' in line and not line.strip().startswith('-'):
            skip_until_next_schema = False
            new_lines.append(line)
        # Continue skipping
        continue
    
    new_lines.append(line)

# Write back the modified content
with open('libs/api-client-go/api/openapi.yaml', 'w') as f:
    f.writelines(new_lines)

print("Removed ComputerUse schemas from OpenAPI spec")
