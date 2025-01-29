$scripts = @(
	{
		Set-ItemProperty -LiteralPath 'Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoLogonCount' -Type 'DWord' -Force -Value 0;
	};
	{
		Add-WindowsCapability -Online -Name OpenSSH.Server;
		Set-Service -Name sshd -StartupType 'Automatic';
		Set-Service -Name ssh-agent -StartupType 'Automatic';
		Start-Service ssh-agent;
		Start-Service sshd;
	};
	{
		New-NetFirewallRule -DisplayName "Allow OpenSSH Inbound" -Direction Inbound -Program "C:\Windows\System32\OpenSSH\sshd.exe" -Action Allow -Profile Any
		New-NetFirewallRule -DisplayName "Allow OpenSSH Outbound" -Direction Outbound -Program "C:\Windows\System32\OpenSSH\sshd.exe" -Action Allow -Profile Any
	};
	{
		mkdir $env:USERPROFILE\.ssh
		$authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCa89hPd0mxguYGSVhnqz2HcRkohbiYNPl+ibbdlOnxx5/w9cCDQWCaipBTC8FZAXv2bBkdgL0nzRoEL7r7F/zvYjR2FqPkLGCsDypiOS94R2CDiRTXgzo7v1AadgCLgMe3VBph78qaEiMu3buMexN/QF0VUE2rfBtDLZaOSrteWAygXALZp7frWtpQodDNkYM0K3LSvWjNG5HDPXagyNYjeSos1z/8zi0Su+syo0qjkuJY5GSBV4s6TgNJAOt9CFzTp/Q3Uts7UoL7tqUuw4W/+hf+ITErZ8NyxIQyUMH8yZEt2PQGToBwlPrshqoq3ftYQrPAVqHrason8TnYCLHToiOwkYrzoa3YCusUL/HYeUGHdocFS++nBG22ANpAOeD+h7UQliiCzRhPt2oph8vTIJ/LeSnosf3F05Nl6AXzjhTvQ5mko16xOTxq8OW3QTk3hWsmGJwlJb5zne8XQ4MWiHgeNq0iwJ5EiVHkQPgTd8Z9pzjc54iMMKR+zmYacWc= Unsecure key for use with guests. DO NOT EXPOSE THEIR SSH PORTS TO THE INTERNET, EVER"
		$authorized_keys | Add-Content -Path $env:USERPROFILE\.ssh\authorized_keys
		$authorized_keys | Add-Content -Path $env:ProgramData\ssh\administrators_authorized_keys
		icacls $env:USERPROFILE\.ssh\authorized_keys /inheritance:r /grant:r "$($env:USERNAME):(F)"
		icacls $env:ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant:r "$($env:USERNAME):(F)"
	};
	{
		("Port 10022`n" + (Get-Content -Raw $env:ProgramData\ssh\sshd_config)) | Set-Content $env:ProgramData\ssh\sshd_config
	};
	{
		(Get-AppxProvisionedPackage -Online -LogLevel Warnings | Where-Object -Property DisplayName -EQ Microsoft.DesktopAppInstaller).InstallLocation -replace '%SYSTEMDRIVE%', $env:SystemDrive | Add-AppxPackage -Register -DisableDevelopmentMode
		winget.exe source update --disable-interactivity
	};
	{		
		winget.exe install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-package-agreements --accept-source-agreements --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
	};
	{
		winget.exe install --id=Git.Git -e --force --accept-package-agreements --accept-source-agreements
	};
	{
		& "C:\Program Files\Git\bin\git.exe" clone https://github.com/dolphin-emu/dolphin.git "$env:USERPROFILE\dolphin"
		cd "$env:USERPROFILE\dolphin"
		& "C:\Program Files\Git\bin\git.exe" submodule update --init --recursive
	};
	{
		Copy-Item -Path "C:\Windows\Setup\hosts" -Destination "C:\Windows\System32\Drivers\etc\hosts" -Force -ErrorAction Stop
	};
	{
		Stop-Computer;
	};
);

& {
	[float] $complete = 0;
	[float] $increment = 100 / $scripts.Count;
	foreach( $script in $scripts ) {
		Write-Progress -Activity 'Running scripts to finalize your Windows installation. Do not close this window.' -PercentComplete $complete;
		& $script;
		$complete += $increment;
	}
} *>&1 >> "C:\Windows\Setup\Scripts\FirstLogon.log";