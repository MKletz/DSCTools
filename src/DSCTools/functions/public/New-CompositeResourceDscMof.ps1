function New-CompositeResourceDscMof {
<#
.SYNOPSIS
    Generates a MOF file for a specified composite resource with the provided parameters.
.DESCRIPTION
    Generates a MOF file for a specified composite resource with the provided parameters.
.PARAMETER Module
    Name of the module containing the composite resource.
.PARAMETER OutPath
    Directory to generate the MOF file in. Default is $ENV:TEMP
.PARAMETER Parameters
    Parameters for the resource in hashtable format. Default is an empty hashtable for no parameters.
.PARAMETER Resource
    Name of the composite resource.
.EXAMPLE
    Get-ChildItem -Path "C:\DSCConfigs\Output" -File -Filter "*.mof" -Recurse | ConvertFrom-DscMof
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory)]
        [string]$Module,
        [string]$OutPath = $ENV:TEMP,
        [Hashtable]$Parameters = @{},
        [Parameter(Mandatory)]   
        [string]$Resource
    )

    Process {
        # Parameters are passed in as configuration data to perserve data types
        [string[]]$ResourceParameters = @()
        ($Parameters.Keys) | ForEach-Object -Process {
            $ResourceParameters += "$($_) = $('$Node').$($_)"
        }
        
        $Parameters.NodeName = 'temp'

        $ConfigurationData = @{
            'AllNodes' = @(
                $Parameters
            )
        }
        
        [string]$GUID = "$(New-Guid)".Replace('-','_')
        [string]$UniqueConfigName = "temp_$($GUID)"

        [string]$Template = '
            param($ConfigurationData,$OutPath)
            
            Configuration {0} {{
                Import-DSCResource -Module "{1}" -Name "{2}"
                Node "temp" {{
                    {2} "name" {{
                    {3}
                    }}
                }}
            }}
            {0} -ConfigurationData $ConfigurationData -OutputPath $OutPath'
        
        $ScriptBlock = $Template -f $UniqueConfigName,$Module,$Resource,($ResourceParameters -join "`n")
        
        Invoke-Command -ScriptBlock ([scriptblock]::Create($ScriptBlock)) -ArgumentList $ConfigurationData,$OutPath
    }
}
