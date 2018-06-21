$credential = (Get-Credential -UserName administrator@tertittenoffice.onmicrosoft.com -Message 'passord')
Connect-MsolService -Credential $credential








