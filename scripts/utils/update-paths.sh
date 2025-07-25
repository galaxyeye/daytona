#!/bin/bash
# 更新其他文档中的路径引用

# 更新docs目录下的文档
echo "更新文档中的路径引用..."

# 检查是否需要更新其他文档
find /workspaces/daytona/docs -name "*.md" -exec grep -l "scripts/setup-env.py\|scripts/quick-setup-env.py\|scripts/validate-env.py" {} \;

# 如果有引用，可以批量替换
# sed -i 's/scripts\/setup-env\.py/scripts\/config\/setup-env.py/g' /workspaces/daytona/docs/*.md
# sed -i 's/scripts\/quick-setup-env\.py/scripts\/config\/quick-setup-env.py/g' /workspaces/daytona/docs/*.md  
# sed -i 's/scripts\/validate-env\.py/scripts\/config\/validate-env.py/g' /workspaces/daytona/docs/*.md

echo "路径更新完成！"
