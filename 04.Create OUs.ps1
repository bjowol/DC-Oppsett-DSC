<#
en typisk struktur ser slik  ut:
$OU = "Tertitten.no"                        <-- Domenenavn her
$SubOUs =   "Administrasjon",               <-- Diverse avdelinger her kan splittes ved en "/", men bare i en underavdeling
            "Interaksjonsdesign",
            "Systemutvikling",
            "Salg",
            "Ledelse",
            "Enheter",
            "Enheter/Klienter",
            "Enheter/Tanking",
            "Enheter/Servere"
#>

$OU = "Tertitten.no"
$SubOUs =   "Administrasjon",
            "Interaksjonsdesign",
            "Systemutvikling",
            "Salg",
            "Ledelse",
            "Enheter",
            "Enheter/Klienter",
            "Enheter/Tanking",
            "Enheter/Servere"

$RootDN = (Get-ADDomain).DistinguishedName

New-ADOrganizationalUnit $OU
New-AdGroup -GroupCategory Security -Path "ou=$OU,$RootDN" -GroupScope Global -Name "$($OU)Group"

foreach($SubOU in $SubOUs) {
    $OUs = $SubOU.split("/")
    
    $OUTree = "OU=$OU,$RootDN";

    for($i = 0; $i -lt $OUs.Count-1; $i++) {
        $OUTree = "OU=$($OUs[$i]),$OUTree"
    }

    New-ADOrganizationalUnit $OUs[$OUs.Count-1] -Path $OUTree -ProtectedFromAccidentalDeletion $false
    New-AdGroup -GroupCategory Security -Path "ou=$($OUs[$OUs.Count-1]),$OUTree" -GroupScope Global -Name "$($OUs[$OUs.Count-1])Group"
}


