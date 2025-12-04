@echo off

chcp 65001

set "KEY=HKCU\Software\Winlator\WFM\ContextMenu\Extra Menu"

:: 添加各个菜单命令（全部作为 Extra Menu 项下的值）
reg add "%KEY%" /v "导入注册表(Import_reg_file)"             /t REG_SZ /d "reg import \"%%FILE%%\"" /f
reg add "%KEY%" /v "安装MSI文件(Setup_msi_file)"             /t REG_SZ /d "msiexec /i \"%%FILE%%\"" /f
reg add "%KEY%" /v "编辑文件(Notepad2_edit)"               /t REG_SZ /d "Z:\\extra-res\\notepad2\\Notepad2.exe \"%%FILE%%\"" /f
