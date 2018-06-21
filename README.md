# DC-Oppsett-DSC
sett opp en DC relativt rask ved hjelp av Desired State configurasjoner
Script som må tilpasses er: 
02.DSC.ps1 Her må variabler øverst i scriptet endres. Vær obs på resart-computer i slutten av scriptet
startup.bat Her må du forsikre deg om at startup.bat inneholder riktig path til filen 03.ResumeDSC.ps1
04.Create OUs.ps1 Her må du endre på din OU struktur. Domenenavn skal være øverst. Deretter følgende:
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
Du kan bare lage SUB'ous en gang. Ikke bruk flere / for å bla lenger ned i OU strukturen, scriptet er ikke laget for det.
05.Setup Shares.ps1 her må du endre på sharenavn, og gruppenavnene skal hete det samme som OU navnet+Group på slutten.
               #Sharename     #Tilgang
$smb_shares = ("HomeFolders", "Tertitten.noGroup"), `
("Administrasjon", "AdministrasjonGroup"), `
("Interaksjonsdesign", "InteraksjonsdesignGroup"), `
("Systemutvikling","SystemutviklingGroup"), `
("Salg","SalgGroup"), `
("Felles","Tertitten.noGroup"),
("Ledelse","LedelseGroup")

07. WDS Installasjon_med_capture_image.ps1 her må det endres på markerte steder.
07. WDS Installsjon_Fagprøve er en eldre versjon av dette scriptet

Ellers må Users.CSV endres i Users mappen.
 
 
