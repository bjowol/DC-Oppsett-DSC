Import-Module ActiveDirectory

#variabel som må endres til bruk. dette er gruppen i AD brukerene skal legges inn i
$DomainUserGroup = "DP.localGroup"

$ServerName = $env:COMPUTERNAME;
$Users = Import-Csv -Delimiter ';' -Path "$PSScriptRoot\Users\Users.csv"
$Users = Import-Csv -Delimiter ';' -Path ".\Users\Users.csv"

$RootDN = (Get-ADDomain).DistinguishedName
$DomainName = (Get-ADDomain).DNSRoot
$RootHomeFolderShare = 'Z:\Shares\HomeFolders'

if(-not(Test-Path -Path $RootHomeFolderShare)){
    try {
        New-Item -ItemType Directory -Path $RootHomeFolderShare
    }
    catch {
        throw $_
    }
}

foreach ($user in $Users) {
    $OU = $user.OU
    $password = $user.Password
    $name = $user.Name
    $firstname = $user.Firstname
   
    $fullName = "$firstname $name"
    $SAM = "$($firstname.substring(0, 1))$name"
    $HomeFolderPath = "$RootHomeFolderShare\$SAM"
    $UPN = $SAM + '@' + $DomainName

    #$OUPath = "OU=Tertitten.Local,$RootDN"
    $OUPath = $RootDN
    $OUSplit = $OU.split('/')


    foreach($TmpOU in $OUSplit) {
        $OUPath = "OU=$TmpOU,$OUPath"
    }

    New-ADUser -ChangePasswordAtLogon $false -HomeDirectory "\\$ServerName\HomeFolders\$SAM" -Name $fullName `
    -SamAccountName $SAM -UserPrincipalName $UPN -GivenName $firstname -Surname $name `
    -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -Enabled $true -Path $OUPath

    #Legger bruker til gruppene den skal vre i
    Add-ADGroupMember -Identity $DomainUserGroup -Members $SAM
    foreach($TmpOU in $OUSplit) {
        Add-ADGroupMember "$($TmpOU)Group" $SAM
    }

    #Gir brukeren full tilgang til mappen sin
    New-Item $HomeFolderPath -type Directory

    #Skruer av tilgang inheritence
    $acl = Get-Acl $HomeFolderPath
    $acl.SetAccessRuleProtection($true, $true);
    Set-Acl $HomeFolderPath $acl

    #Henter tilgangene soim er konfigurert på mappen
    $acl = Get-Acl $HomeFolderPath

    #Fjenrer alle tilganger som er tildelt på mappen for å starte fra scratch
    $acl.Access | %{$acl.RemoveAccessRule($_)}

    #Gir brukeren og Administrators full tilgang til mappen
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($SAM,'Modify','ContainerInherit, ObjectInherit','None','Allow');
    $acl.SetAccessRule($Ar);
    $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators",'Modify','ContainerInherit, ObjectInherit','None','Allow');
    $acl.SetAccessRule($Ar);

    #Applyer tilgangene til mappen
    Set-Acl $HomeFolderPath $acl
    
    }