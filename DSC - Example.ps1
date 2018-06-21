Configuration MyDscConfiguration {

    Node "localhost" {
        WindowsFeature MyFeatureInstance {
            Ensure = "Present"
            Name =  "RSAT"
        }
        WindowsFeature My2ndFeatureInstance {
            Ensure = "Present"
            Name = "Bitlocker"
        }
        WindowsFeature xADDS {
            Ensure = "Present"
            Name = "ADDS"
        }
    }
}

Start-DscConfiguration0 -JobName MyDscConfiguration
Test-DscConfiguration -ComputerName localhost




MyDscConfiguration
configuration Name {
    # One can evaluate expressions to get the node list
    # E.g: $AllNodes.Where("Role -eq Web").NodeName
    node ("Node1","Node2","Node3")
    {
        # Call Resource Provider
        # E.g: WindowsFeature, File
        WindowsFeature FriendlyName
        {
            Ensure = "Present"
            Name = "Feature Name"
        }

        File FriendlyName
        {
            Ensure = "Present"
            SourcePath = $SourcePath
            DestinationPath = $DestinationPath
            Type = "Directory"
            DependsOn = "[WindowsFeature]FriendlyName"
        }
        WindowsFeature Bitlocker
        {
            Ensure = $true
            Name = "Bitlocker"

        }
    }
}
Get-DscConfigurationStatus -all