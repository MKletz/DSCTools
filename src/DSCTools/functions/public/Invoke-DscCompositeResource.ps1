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
                'ResourceName',
                'ModuleVersion',
                'ConfigurationName',
                'ResourceID',
                'ModuleName',
                'SourceInfo'
            )
            
            $MOF = New-DscMof -ModuleName $ModuleName -Resource $Name -Property $Property
            ConvertFrom-Mof -Path $MOF | ForEach-Object -Process {
                $InvokeSplat = @{
                    Name = $_['ResourceName']
                    #ModuleName = [Microsoft.PowerShell.Commands.ModuleSpecification]@{ModuleName=$_['ModuleName'];ModuleVersion=$_['ModuleVersion']}
                    ModuleName = $_['ModuleName']
                    Method = $Method
                    Property = $_
                }

                $ResourceProperties = (Get-DscResourceFromCache -Resource $_['ResourceName'] -Module $_['ModuleName'])
                Foreach ($Key in $($InvokeSplat['Property'].Keys)) {
                    if ($ResourceProperties.keys -contains $Key) {
                        $InvokeSplat['Property'][$Key] = ($InvokeSplat['Property'][$Key] -as $ResourceProperties[$Key].TypeObject)
                    }
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
