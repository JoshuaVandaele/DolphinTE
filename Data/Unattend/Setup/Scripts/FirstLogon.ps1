function Prepend-ToFile {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$TextToPrepend,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$FilePath
    )

    $fileContent = $TextToPrepend + "`n" + (Get-Content -Raw $FilePath)
    Set-Content -Path $FilePath -Value $fileContent
}

function Install-OpenSshServer {
    Add-WindowsCapability -Online -Name OpenSSH.Server

    Set-Service -Name sshd -StartupType Automatic
    Set-Service -Name ssh-agent -StartupType Automatic

    New-NetFirewallRule -DisplayName "Allow OpenSSH Inbound" -Direction Inbound -Program "C:\Windows\System32\OpenSSH\sshd.exe" -Action Allow -Profile Any
    New-NetFirewallRule -DisplayName "Allow OpenSSH Outbound" -Direction Outbound -Program "C:\Windows\System32\OpenSSH\sshd.exe" -Action Allow -Profile Any

    Start-Service ssh-agent
    Start-Service sshd

    $sshFolder = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path -Path $sshFolder)) {
        New-Item -ItemType Directory -Path $sshFolder
    }

    Prepend-ToFile "Port 10022" "$env:ProgramData\ssh\sshd_config"

    $authorizedKeysContent = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCa89hPd0mxguYGSVhnqz2HcRkohbiYNPl+ibbdlOnxx5/w9cCDQWCaipBTC8FZAXv2bBkdgL0nzRoEL7r7F/zvYjR2FqPkLGCsDypiOS94R2CDiRTXgzo7v1AadgCLgMe3VBph78qaEiMu3buMexN/QF0VUE2rfBtDLZaOSrteWAygXALZp7frWtpQodDNkYM0K3LSvWjNG5HDPXagyNYjeSos1z/8zi0Su+syo0qjkuJY5GSBV4s6TgNJAOt9CFzTp/Q3Uts7UoL7tqUuw4W/+hf+ITErZ8NyxIQyUMH8yZEt2PQGToBwlPrshqoq3ftYQrPAVqHrason8TnYCLHToiOwkYrzoa3YCusUL/HYeUGHdocFS++nBG22ANpAOeD+h7UQliiCzRhPt2oph8vTIJ/LeSnosf3F05Nl6AXzjhTvQ5mko16xOTxq8OW3QTk3hWsmGJwlJb5zne8XQ4MWiHgeNq0iwJ5EiVHkQPgTd8Z9pzjc54iMMKR+zmYacWc= Unsecure key for guests. DO NOT EXPOSE THEIR SSH PORTS TO THE INTERNET, EVER"
    $authorizedKeysContent | Add-Content -Path "$env:ProgramData\ssh\administrators_authorized_keys"

    $acl = Get-Acl "$env:ProgramData\ssh\administrators_authorized_keys"
    $acl.SetAccessRuleProtection($true, $false)
    $administratorsRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "Allow")
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")
    $acl.SetAccessRule($administratorsRule)
    $acl.SetAccessRule($systemRule)
    $acl | Set-Acl

    New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\Setup\SSHShell.bat" -PropertyType String -Force
}

function Install-Winget {
    (Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ "Microsoft.DesktopAppInstaller").InstallLocation -replace '%SYSTEMDRIVE%', $env:SystemDrive | Add-AppxPackage -Register -DisableDevelopmentMode
    winget.exe source update --disable-interactivity
}

function Install-Applications {
    winget.exe install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-package-agreements --accept-source-agreements --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    winget.exe install --id Git.Git -e --force --accept-package-agreements --accept-source-agreements
}

function Clone-Dolphin {
    $gitExe = "C:\Program Files\Git\bin\git.exe"
    $dolphinFolder = "$env:USERPROFILE\dolphin"
    $shortcutPath = Join-Path $env:USERPROFILE "Desktop\Dolphin.lnk"

    & $gitExe clone https://github.com/dolphin-emu/dolphin.git $dolphinFolder
    & $gitExe -C $dolphinFolder submodule update --init --recursive

    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $dolphinFolder
    $shortcut.WorkingDirectory = $dolphinFolder
    $shortcut.Save()

    $shellApplication = New-Object -ComObject Shell.Application
    $shellApplication.Namespace($dolphinFolder).Self.InvokeVerb("pintohome")
}

function Remove-WindowsRecoveryPartition {
    Disable-ComputerRestore -Drive "C:"

    $partitions = Get-Partition -DiskNumber 0
    $cPartition = $partitions | Where-Object DriveLetter -eq 'C'
    $recoveryPartition = $partitions | Where-Object Type -eq 'Recovery'

    $diskpartScript = @"
select disk 0
select partition $($recoveryPartition[0].PartitionNumber)
delete partition override
select partition $($cPartition[0].PartitionNumber)
extend
"@

    $tempFile = [System.IO.Path]::GetTempFileName()
    $diskpartScript | Out-File -FilePath $tempFile -Encoding ASCII
    diskpart /s $tempFile
    Remove-Item -Path $tempFile -Force
}

function Set-HighPerformancePowerPlan {
    $highPerfPlan = Get-WmiObject -Namespace root\cimv2\power -Class Win32_PowerPlan | Where-Object ElementName -eq "High performance"
    if ($highPerfPlan) { $highPerfPlan.Activate() }
}

$scripts = @(
    { Set-ItemProperty -LiteralPath 'Registry::HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name 'AutoLogonCount' -Type DWord -Force -Value 0 },
    { Install-OpenSshServer },
    { Install-Winget },
    { Install-Applications },
    { Clone-Dolphin },
    { Move-Item -Path "C:\Windows\Setup\hosts" -Destination "C:\Windows\System32\Drivers\etc\hosts" -Force -ErrorAction Stop },
    { Set-HighPerformancePowerPlan },
    { Remove-WindowsRecoveryPartition },
    { Stop-Computer }
)

& {
	[float] $complete = 0
	[float] $increment = 100 / $scripts.Count
	foreach( $script in $scripts ) {
		Write-Progress -Activity 'Running scripts to finalize your Windows installation. Do not close this window.' -PercentComplete $complete
        Write-Output "--- $script"
		& $script
		$complete += $increment
	}
} *>&1 >> "C:\Windows\Setup\Scripts\FirstLogon.log"
