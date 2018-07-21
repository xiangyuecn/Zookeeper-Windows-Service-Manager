::zookeeper windows服务安装管理器
::通过本管理器可以实现zookeeper系统服务的安装卸载，启动和关闭
::xiangyuecn编写，学习zookeeper之用，还没弄懂怎么配置zookeeper，先把安装问题先解决了，不然服务器一注销zookeeper也自动关掉了
::2018-07-21

::说明：
::【1】把【5】内的文件放到zookeeper根目录，点击运行start.bat即可
::【2】初次运行请先安装，安装成功后将会出现卸载功能，否则代表出错，其他功能也是这个道理，这个没有很明了的错误说明的
::【3】安装后生成的winswXXX.xml文件不可删除，否则无法卸载和启动
::【4】服务启动后winsw会产生3个log文件，可以删除
::【5】此程序由
::		start.bat 主脚本
::		tp.vbs 配置文件生成脚本
::		winsw1.9.exe windows服务安装器，下载地址：http://download.java.net/maven/2/com/sun/winsw/winsw/ 配置介绍：https://kenai.com/projects/winsw/pages/ConfigurationSyntax
::	这几个文件组成，缺一不可

@echo off

::配置部分---------------------------

::可选非根目录配置模板，本地测试配置
set configTxt=D:\Works\文档\程序配置文件\zookeeper\config-local.txt
if not exist %configTxt% (
	set configTxt=
)

::配置文件夹
set confPath=conf\zoo.cfg
::安装器路径，不要后缀
set svsInstall=winsw1.9
::服务名称
set svs=Zookeeper

::执行部分---------------------------
color 8f

:main
set dir=%~d0%~p0
set dirPath=%dir:~0,-1%
set stack=
set stackErr=0
%~d0
cd %dir%

cls
echo               *****说明介绍请看源代码 by xiangyuecn 嘿咻嘿咻*****
echo.
if not "%msg%"=="" echo -------%msg%-------

set msg=
set datetime=%date:~0,10% %time:~0,8%
set isRun=false
set isInstall=true
sc query %svs%|findstr /c:"指定的服务未安装">nul&&set isInstall=false
sc query %svs%|findstr /ic:"run">nul&&set isRun=true

if %isRun%==true (
	echo %datetime% %svs%服务运行中...
) else (
	echo %datetime% %svs%服务未运行xxx
)

echo 可以操作：
if not %isRun%==true echo   1:运行
if %isRun%==true (
	echo   2:停止
	echo   3:重启
)
echo   4:从模板更新配置
echo        需在根目录新建config.txt文件或"%configTxt%"，格式(h)
echo.
echo   5:退出
echo.
if %isInstall%==false (
	echo   0:安装服务
) else (
	echo   0:卸载服务/恢复%svsInstall%.xml配置
)

set step=
set /p step=请输入序号:
echo.

if "%step%"=="0" goto step_install
if "%step%"=="1" goto step_run
if "%step%"=="2" goto step_stop
if "%step%"=="3" goto step_reset
if "%step%"=="4" goto step_tpconfig
if "%step%"=="5" exit
if "%step%"=="h" goto tpconfighelp

goto step_end

:tpconfighelp
cls
echo	config.txt文件可用格式：
echo          内容支持时间变量
echo              如:logs/access_{y}{m}{d} {h}{M}{s}.log
echo              为:logs/access_20130306 122530.log
echo.
echo          内容支持宏定义和替换
echo              DEF(标识) 宏名称=宏内容 (标识)END
echo              宏名称支持^&、^<、^>、/、_、-、空格、换行、字母、数字、文字组合，宏内容可以多行
pause
goto step_end

:step_run
	if not %isRun%==true (
		echo 启动中...
		net start %svs%
		if errorlevel 1 (
			set stackErr=1
			set msg=！！启动服务失败！！
			pause
		) else (
			set isRun=true
			set msg=已启动服务
		)
	)
	goto step_end

:step_stop
	if %isRun%==true (
		echo 关闭中...
		net stop %svs%
		if errorlevel 1 (
			set stackErr=1
			set msg=！！关闭服务失败！！
			pause
		) else (
			set isRun=false
			set msg=已关闭服务
		)
	)
	goto step_end

:step_reset
	if %isRun%==true (
		echo 重启中...
		
		set stack=step_reset_stop
		set stackErr=0
		goto step_stop
		:step_reset_stop
		if %stackErr%==0 (
			set stack=step_reset_run
			goto step_run
			:step_reset_run
			set stack=
		)
		
		if %stackErr%==0 (
			set msg=重启成功
		) else (
			set msg=%msg%!!不能重启!!
		)
	)
	goto step_end


:step_tpconfig
	if "%configTxt%"=="" (
		set tpPath=%dir%config.txt
	) else (
		set tpPath=%configTxt%
	)
	if not exist %tpPath% (
		set stackErr=1
		echo %tpPath%不存在，请先创建此文件，内容为zoo_sample.cfg的副本
		pause
	) else (
		echo 正在生成配置...
		
		cscript tp.vbs %tpPath% %dir%%confPath%
		if ERRORLEVEL 1 (
			set stackErr=1
			set ms=！！执行生成配置失败！！
			pause
		) else (
			set msg=已生成配置
		)
	)
	goto step_end


:step_install
	if %isInstall%==true goto step_uninstall
	echo 正在安装...

	set stack=step_install_getxml
	set stackErr=0
	goto fn_getInstallXML
	:step_install_getxml
	set stack=

	%svsInstall%.exe install
	set msg=已执行安装，但状态不确认
	goto step_end

:step_uninstall
	set useUninstall=
	echo 确认删除服务请输入y,恢复误删配置h？
	set /p useUninstall=
	if "%useUninstall%"=="h" (
		set stack=step_uninstall_getxml
		set stackErr=0
		goto fn_getInstallXML
		:step_uninstall_getxml
		set stack=
		goto step_uninstall_getxml_exit
	) else (
		if "%useUninstall%"=="y" (
			set stack=step_uninstall_stop
			set stackErr=0
			goto step_stop
			:step_uninstall_stop
			set stack=
			
			if %stackErr%==0 (
				echo 正在卸载...
				%svsInstall%.exe uninstall
				set msg=已执行卸载，但状态不确认
			) else (
				set msg=%msg%！！卸载失败！！
			)
		)
	)
	:step_uninstall_getxml_exit
	goto step_end

:step_end
	if "%stack%"=="" (
		cls
		goto main
	) else (
		goto %stack%
	)

:fn_getInstallXML
	echo ^<?xml version="1.0" encoding="GBK"?^>>%svsInstall%.xml
	echo ^<service^>>>%svsInstall%.xml
	echo 	^<!-->>%svsInstall%.xml
	echo 	安装服务>>%svsInstall%.xml
	echo 	cmd:^>winws.exe install>>%svsInstall%.xml
	echo 	卸载服务>>%svsInstall%.xml
	echo 	cmd:^>winws.exe uninstall>>%svsInstall%.xml
	echo 	--^>>>%svsInstall%.xml
	echo 	^<id^>%svs%^</id^>>>%svsInstall%.xml
	echo 	^<name^>%svs%^</name^>>>%svsInstall%.xml
	echo 	^<description^>%svs%服务，由安装器安装，请用本安装器卸载^</description^>>>%svsInstall%.xml
	echo 	^<!--依赖服务--^>>>%svsInstall%.xml
	echo 	^<depend^>^</depend^>>>%svsInstall%.xml
	echo 	^<!--执行程序路径--^>>>%svsInstall%.xml
	echo 	^<executable^>java^</executable^>>>%svsInstall%.xml
	echo 	^<!--日志目录--^>>>%svsInstall%.xml
	echo 	^<logpath^>%dir%^</logpath^>>>%svsInstall%.xml
	echo 	^<!--日志记录方式reset roll append--^>>>%svsInstall%.xml
	echo 	^<logmode^>append^</logmode^>>>%svsInstall%.xml
	echo 	^<!--参数--^>>>%svsInstall%.xml
	echo 	^<arguments^>"-Dzookeeper.log.dir=%dirPath%" "-Dzookeeper.root.logger=INFO,CONSOLE" -cp "%dir%*;%dir%lib\*;%dir%conf" org.apache.zookeeper.server.quorum.QuorumPeerMain "%dir%%confPath%"^</arguments^>>>%svsInstall%.xml
	echo ^</service^>>>%svsInstall%.xml
	goto %stack%