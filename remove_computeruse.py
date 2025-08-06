#!/usr/bin/env python3

import re

# Read the OpenAPI file
with open('libs/api-client-go/api/openapi.yaml', 'r') as f:
    content = f.read()

# Remove all computeruse paths and their complete definitions
# This regex matches from a computeruse path to the next path or end of paths section
pattern = r'  /toolbox/\{sandboxId\}/toolbox/computeruse/[^:]*:.*?(?=  /[^t]|\ncomponents:|\nservers:|\n$)'
content = re.sub(pattern, '', content, flags=re.DOTALL)

# Also remove the ComputerUse schemas from components section
content = re.sub(r'    ComputerUseStartResponse:.*?(?=    [A-Z][^:]*:|components:|\n$)', '', content, flags=re.DOTALL)
content = re.sub(r'    ComputerUseStopResponse:.*?(?=    [A-Z][^:]*:|components:|\n$)', '', content, flags=re.DOTALL)
content = re.sub(r'    ComputerUseStatusResponse:.*?(?=    [A-Z][^:]*:|components:|\n$)', '', content, flags=re.DOTALL)

# Write back the modified content
with open('libs/api-client-go/api/openapi.yaml', 'w') as f:
    f.write(content)

print("Removed computer use related content from OpenAPI spec")
