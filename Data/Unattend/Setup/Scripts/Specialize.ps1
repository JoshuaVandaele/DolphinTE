$scripts = @(
	{
		ReAgentc.exe /disable;
		Remove-Item -LiteralPath 'C:\Windows\System32\Recovery\Winre.wim' -Force -ErrorAction 'SilentlyContinue';
	};
	{
		reg.exe add "HKLM\SYSTEM\Setup\MoSetup" /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f;
	};
	{
		reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v BypassNRO /t REG_DWORD /d 1 /f;
	};
	{
		net.exe accounts /lockoutthreshold:0;
	};
	{
		net.exe accounts /maxpwage:UNLIMITED;
	};
	{
		reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f
	};
	{
		reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f;
	};
	{
		reg.exe add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d 1 /f;
	};
);

& {
	[float] $complete = 0;
	[float] $increment = 100 / $scripts.Count;
	foreach( $script in $scripts ) {
		Write-Progress -Activity 'Running scripts to customize your Windows installation. Do not close this window.' -PercentComplete $complete;
		& $script;
		$complete += $increment;
	}
} *>&1 >> "C:\Windows\Setup\Scripts\Specialize.log";
