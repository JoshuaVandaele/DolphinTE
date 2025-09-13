$scripts = @(
    {
        Disable-WindowsOptionalFeature -Online -FeatureName "WinRE" -NoRestart -ErrorAction SilentlyContinue
        Remove-Item -Recurse -LiteralPath 'C:\Windows\System32\Recovery\' -Force -ErrorAction SilentlyContinue
    };
    {
        New-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -PropertyType DWord -Value 1 -Force
    };
    {
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "BypassNRO" -PropertyType DWord -Value 1 -Force
    };
    {
        net.exe accounts /lockoutthreshold:0
    };
    {
        net.exe accounts /maxpwage:UNLIMITED
    };
    {
        New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -PropertyType DWord -Value 0 -Force
    };
    {
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -PropertyType DWord -Value 0 -Force
    };
    {
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "PagingFiles" -PropertyType String -Value "" -Force
    };
    {
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -PropertyType DWord -Value 1 -Force
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
