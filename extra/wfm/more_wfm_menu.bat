@echo off

chcp 65001

set "KEY=HKCU\Software\Winlator\WFM\ContextMenu\Extra Menu"

:: 添加各个菜单命令（全部作为 Extra Menu 项下的值）
reg add "%KEY%" /v "导入注册表(Import_reg_file)"             /t REG_SZ /d "reg import \"%%FILE%%\"" /f
reg add "%KEY%" /v "安装MSI文件(Setup_msi_file)"             /t REG_SZ /d "msiexec /i \"%%FILE%%\"" /f
reg add "%KEY%" /v "编辑文件(Notepad2_edit)"               /t REG_SZ /d "Z:\\extra-res\\notepad2\\Notepad2.exe \"%%FILE%%\"" /f


echo "现在wfm修改为64位7zip解压，避免了老版本的7zip存在的潜在的安全和性能问题"

echo "（如果需要适配所有改版的bat脚本，请运行new64_7zip.bat<=位于99.extra或Z:\extra）"

echo "添加了更好的轻量级文本编辑器，与msi和reg文件功能注册在了wfm的对文件右键菜单里--Extra Menu"

echo "此版本wfm单击user目录可以直接访问C:\users\xuser，也适配所有wine/windows环境"

cmd