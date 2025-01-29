function Prepend-ToFile {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$TextToPrepend,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$FilePath
    )

    $content = $TextToPrepend + "`n" + (Get-Content -Raw $FilePath)
    Set-Content -Path $FilePath -Value $content
}


function SetupSSH {
    Add-WindowsCapability -Online -Name OpenSSH.Server;

    Set-Service -Name sshd -StartupType 'Automatic';
    Set-Service -Name ssh-agent -StartupType 'Automatic';

    New-NetFirewallRule -DisplayName "Allow OpenSSH Inbound" -Direction Inbound -Program "C:\Windows\System32\OpenSSH\sshd.exe" -Action Allow -Profile Any;
    New-NetFirewallRule -DisplayName "Allow OpenSSH Outbound" -Direction Outbound -Program "C:\Windows\System32\OpenSSH\sshd.exe" -Action Allow -Profile Any;

    Start-Service ssh-agent;
    Start-Service sshd;

    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path -Path $sshDir)) {
        mkdir $sshDir
    }

    Prepend-ToFile "Port 10022" "$env:ProgramData\ssh\sshd_config"
    $authorized_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCa89hPd0mxguYGSVhnqz2HcRkohbiYNPl+ibbdlOnxx5/w9cCDQWCaipBTC8FZAXv2bBkdgL0nzRoEL7r7F/zvYjR2FqPkLGCsDypiOS94R2CDiRTXgzo7v1AadgCLgMe3VBph78qaEiMu3buMexN/QF0VUE2rfBtDLZaOSrteWAygXALZp7frWtpQodDNkYM0K3LSvWjNG5HDPXagyNYjeSos1z/8zi0Su+syo0qjkuJY5GSBV4s6TgNJAOt9CFzTp/Q3Uts7UoL7tqUuw4W/+hf+ITErZ8NyxIQyUMH8yZEt2PQGToBwlPrshqoq3ftYQrPAVqHrason8TnYCLHToiOwkYrzoa3YCusUL/HYeUGHdocFS++nBG22ANpAOeD+h7UQliiCzRhPt2oph8vTIJ/LeSnosf3F05Nl6AXzjhTvQ5mko16xOTxq8OW3QTk3hWsmGJwlJb5zne8XQ4MWiHgeNq0iwJ5EiVHkQPgTd8Z9pzjc54iMMKR+zmYacWc= Unsecure key for use with guests. DO NOT EXPOSE THEIR SSH PORTS TO THE INTERNET, EVER"
    $authorized_keys | Add-Content -Path "$env:ProgramData\ssh\administrators_authorized_keys"

    $acl = Get-Acl "$env:ProgramData\ssh\administrators_authorized_keys"
    $acl.SetAccessRuleProtection($true, $false)
    $administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule("Administrators","FullControl","Allow")
    $systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
    $acl.SetAccessRule($administratorsRule)
    $acl.SetAccessRule($systemRule)
    $acl | Set-Acl

    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\Setup\SSHShell.bat" -PropertyType String -Force
}

function InstallWinget {
    (Get-AppxProvisionedPackage -Online -LogLevel Warnings | Where-Object -Property DisplayName -EQ Microsoft.DesktopAppInstaller).InstallLocation -replace '%SYSTEMDRIVE%', $env:SystemDrive | Add-AppxPackage -Register -DisableDevelopmentMode
    winget.exe source update --disable-interactivity
}

function InstallApps {
    winget.exe install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-package-agreements --accept-source-agreements --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    winget.exe install --id Git.Git -e --force --accept-package-agreements --accept-source-agreements
}

function CloneDolphin {
    & "C:\Program Files\Git\bin\git.exe" clone https://github.com/dolphin-emu/dolphin.git "$env:USERPROFILE\dolphin"
    cd "$env:USERPROFILE\dolphin"
    & "C:\Program Files\Git\bin\git.exe" submodule update --init --recursive
}

$scripts = @(
    {Set-ItemProperty -LiteralPath 'Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoLogonCount' -Type 'DWord' -Force -Value 0};
    {SetupSSH};
    {InstallWinget};
    {InstallApps};
    {CloneDolphin};
    {Copy-Item -Path "C:\Windows\Setup\hosts" -Destination "C:\Windows\System32\Drivers\etc\hosts" -Force -ErrorAction Stop};
    {Stop-Computer};
);

& {
	[float] $complete = 0;
	[float] $increment = 100 / $scripts.Count;
	foreach( $script in $scripts ) {
		Write-Progress -Activity 'Running scripts to finalize your Windows installation. Do not close this window.' -PercentComplete $complete;
        Write-Output "--- $script";
		& $script;
		$complete += $increment;
	}
} *>&1 >> "C:\Windows\Setup\Scripts\FirstLogon.log";
