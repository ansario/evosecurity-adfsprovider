# Install the provider

function Gac-Util
{
    param (
        [parameter(Mandatory = $true)][string] $assembly
    )
    try
    {
        $Error.Clear()

        [Reflection.Assembly]::LoadWithPartialName("System.EnterpriseServices") | Out-Null
        [System.EnterpriseServices.Internal.Publish] $publish = New-Object System.EnterpriseServices.Internal.Publish

        if (!(Test-Path $assembly -type Leaf) ) 
            { throw "The assembly $assembly does not exist" }

        if ([System.Reflection.Assembly]::LoadFile($assembly).GetName().GetPublicKey().Length -eq 0 ) 
            { throw "The assembly $assembly must be strongly signed" }

        $publish.GacInstall($assembly)

        Write-Host "`t`t$($MyInvocation.InvocationName): Assembly $assembly gacced"
    }
    catch
    {
        Write-Host "`t`t$($MyInvocation.InvocationName): $_"
    }
}

# check event source
if (!([System.Diagnostics.EventLog]::SourceExists("EvoSecurityProvider")))
{
    New-EventLog -LogName "AD FS/Admin" -Source "EvoSecurityProvider"
    Write-Host "Log source created"
}

Set-location "C:\Program Files\EvoSecurityProvider"
Gac-Util "C:\Program Files\EvoSecurityProvider\EvoSecurityProvider-ADFSProvider.dll"

$typeName = "privacyIDEAADFSProvider.Adapter, privacyIDEA-ADFSProvider, Version=1.3.4.0, Culture=neutral, PublicKeyToken=bf6bdb60967d5ecc"
Register-AdfsAuthenticationProvider -TypeName $typeName -Name "EvoSecurity-ADFSProvider" -ConfigurationFilePath "C:\Program Files\EvoSecurityProvider\config.xml" -Verbose

Restart-Service adfssrv