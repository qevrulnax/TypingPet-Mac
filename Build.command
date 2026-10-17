#!/bin/bash
cd "$(dirname "$0")"
/bin/bash scripts/build.sh
result=$?
echo "完成状态：$result（0 表示成功）"
read -r -p '按回车关闭窗口…'
exit "$result"
