function Invoke-DscCompositeResource {
    <#
    .SYNOPSIS
        Parses a MOF file and converts the resource instances it contains to PowerShell Objects.
    .DESCRIPTION
        Parses a MOF file and converts the resource instances it contains to PowerShell Objects.
    .PARAMETER Path
        The path of the MOF file to parse.
    .EXAMPLE
        Get-ChildItem -Path "C:\DSCConfigs\Output" -File -Filter "*.mof" -Recurse | ConvertFrom-DscMof
    #>
        [CmdletBinding()]
        Param
        (
            [Parameter(Mandatory)]
            [String]$Name,
            [Parameter(Mandatory)]
            [Microsoft.PowerShell.Commands.ModuleSpecification]$ModuleName,
            [Parameter(Mandatory)]
            [ValidateSet('Get','Set','Test')]
            [String]$Method,
            [Hashtable]$Property = @{}
        )
    
        Begin {
        }

        Process {
            [String[]]$ExtraProperties = @(
                'SourceInfo',  
                'ConfigurationName',
                'CimSystemProperties',
                'CimInstanceProperties',
                'ResourceID',
                'ModuleVersion',
                'CimClass',
                'PSComputerName',
                'ModuleName'
            )
            
            $MOF = New-DscMof -ModuleName $ModuleName -Resource $Name -Property $Property
            # The last object is always the Omi_BaseResource:ConfigurationName that isn't needed
            ConvertFrom-Mof -Path $MOF | Select-Object -SkipLast 1 | ForEach-Object -Process {
                # There is some oddities with MOF generation in PSDesiredStateConfiguration. For example Module v1.1 Registery resources will say it was v1.0 causing it not to be found here.
                if($_.ModuleName -eq 'PSDesiredStateConfiguration') {
                    $ModuleObj = 'PSDesiredStateConfiguration'
                }
                else{
                    $ModuleObj = [Microsoft.PowerShell.Commands.ModuleSpecification]@{ModuleName=$_.ModuleName;ModuleVersion=$_.ModuleVersion}
                }

                $Properties = @{}
                $_.psobject.properties | ForEach-Object -Process {
                    $Properties[$_.Name] = $_.Value
                }

                $InvokeSplat = @{
                    Name = ($_.SourceInfo -split '::')[-1]
                    ModuleName = $ModuleObj
                    Method = $Method
                    Property = $Properties
                }

                $ExtraProperties | ForEach-Object -Process {
                    $InvokeSplat['Property'].Remove($_)
                }

                Invoke-DscResource @InvokeSplat
            }
        }

        End {
            Remove-Item -Path $MOF -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
