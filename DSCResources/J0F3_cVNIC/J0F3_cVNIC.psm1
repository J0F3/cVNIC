function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $vNICName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SwitchName,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $VLAN,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumBandwidthWeight,

        [parameter(Mandatory = $false)]
        [ValidateSet('Present','Absent')] 
        [System.String]
        $Ensure = "Present" 

    )

    # Check if Hyper-V module is present for Hyper-V cmdlets 
    if(!(Get-Module -ListAvailable -Name Hyper-V)) 
    { 
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module" 
    } 
        
    $vNIC = Get-VMNetworkAdapter -ManagementOS -Name $vNICName -SwitchName $SwitchName -ErrorAction SilentlyContinue 

    $vNICInfo = @{
        vNICName = $vNIC.Name
        SwitchName = $vNIC.SwitchName
        VLAN = $vNIC.VlanSetting.AccessVlanId
        MinimumBandwidthWeight = $vNIC.BandwidthSetting.MinimumBandwidthWeight
        Ensure = if($vNIC){'Present'}else{'Absent'}
    }

    return $vNICInfo        
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $vNICName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SwitchName,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $VLAN,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumBandwidthWeight,

        [parameter(Mandatory = $false)]
        [ValidateSet('Present','Absent')] 
        [System.String]
        $Ensure = "Present" 
    )

    #Using the Get-TargetResource function to get properties of the team
    $vNIC = Get-TargetResource @PSBoundParameters

    if($vNIC.Ensure -eq 'Present')
    {
        #If the vNIC is present and should be present then the configuration must be incorrect. (Test-TargetResouce ensures that)
        if($Ensure -eq 'Present')
        {
            # VLAN is specified so check VLAN settings
            if($PSBoundParameters.ContainsKey('VLAN'))
            {
                Write-Verbose "Checking VLAN settings..."    
                #check if the specified VLAN is set on the adapter
                if(($vNIC.VLAN -eq $VLAN) -and ($VLAN -ne 0))
                {
                    Write-Verbose "OK. VLAN settings are correct"
                }
                else
                {
                    if($VLAN -eq 0)
                    {
                        Write-Verbose "VLAN ID 0 is specified. Setting the adapter to untagged"
                        Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapter $vNICName -Untagged 
                    }
                    else
                    {
                        Write-Verbose "Wrong VLAN ID is set on the adapter. Setting correct VLAN ID. (old VLAN ID: $($vNIC.VLAN), new VLAN ID: $VLAN)"
                        Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $vNICName -VlanId $VLAN -Access
                    }
                }
            }
            else
            {
                #if no VLAN is specified, check if the adapter has no VLAN ID set. If yes, remove it (set it to untagged)
                if($vNIC.VLAN -ne 0)
                {                
                    Write-Verbose "No VLAN is specified but the adapter has currently a VLAN ID set. Removing the VLAN ID $($vNIC.VLAN)"
                    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapter $vNICName -Untagged
                }
            }

            # MinimumBandwidthWeight is specified so check MinimumBandwidthWeight settings
            if($PSBoundParameters.ContainsKey('MinimumBandwidthWeight'))
            {
                Write-Verbose "Checking MinimumBandwidthWeight QoS settings..."
                if($vNIC.MinimumBandwidthWeight -eq $MinimumBandwidthWeight)
                {
                    Write-Verbose "OK. MinimumBandwidthWeight QoS settings are correct."
                }
                else
                {
                    Write-Verbose "The configured MinimumBandwidthWeight value is not correct. Setting the right value. (old value: $($vNIC.MinimumBandwidthWeight), new value: $MinimumBandwidthWeight)"                
                    Set-VMNetworkAdapter -ManagementOS -VMNetworkAdapterName $vNICName -MinimumBandwidthWeight $MinimumBandwidthWeight                   
                }
            }

        }
        else
        {
            #VMNetworkAdapter is present but should be absent. Remove it. 
            Write-Verbose "Deleting vNIC `"$vNICName`" in the host management OS"
            Remove-VMNetworkAdapter -ManagementOS -VMNetworkAdapterName $vNICName -SwitchName $SwitchName
        }
    }
    else
    {
        #vNIC is absent
        
        #vNIC is absent but should be present. So just create it.
        if($Ensure -eq 'Present')
        {
            Write-Verbose "Adding new vNIC `"$vNICName`" to host management OS"

            Add-VMNetworkAdapter -ManagementOS -VMNetworkAdapterName $vNICName -SwitchName $SwitchName -ErrorAction Stop
            
            #set vlan id if specified
            if($PSBoundParameters.ContainsKey('VLAN'))
            {
                Write-Verbose "Seting VLAN ID"
                Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $vNICName -VlanId $VLAN -Access
            }
            
            #set MinimumBandwidthWeight value f specified
            if($PSBoundParameters.ContainsKey('MinimumBandwidthWeight'))
            {
                Write-Verbose "Seting MinimumBandwidthWeight value"
                Set-VMNetworkAdapter -ManagementOS -VMNetworkAdapterName $vNICName -MinimumBandwidthWeight $MinimumBandwidthWeight
            }
        }       
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $vNICName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $SwitchName,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $VLAN,

        [parameter(Mandatory = $false)]
        [System.UInt32]
        $MinimumBandwidthWeight,

        [parameter(Mandatory = $false)]
        [ValidateSet('Present','Absent')] 
        [System.String]
        $Ensure = "Present"  
    )

    # Check if Hyper-V module is present for Hyper-V cmdlets 
    if(!(Get-Module -ListAvailable -Name Hyper-V)) 
    { 
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module" 
    } 

    Write-Verbose -Message "Checking if VMNetworkAdapter $vNICName is $Ensure..."

    #Using the Get-TargetResource function to get properties of the team
    $vNIC = Get-TargetResource @PSBoundParameters
    
    #VMNetAdapter is present and should be present. Check if the settings are correct.
    if(($vNIC.Ensure -eq 'Present') -and ($Ensure -eq 'Present'))
    {
        Write-Verbose "The vNIC $vNICName is present and should be present."
        #The VMNIC is present and should be present. Lets check the config
        
        Write-Verbose "Checking vNIC configuration..."

        if($PSBoundParameters.ContainsKey('VMName'))
        {
            Write-Verbose "Adapater is connected to a VM. Checking if the adapter is connected with the right VM..."
            if($vNIC.VMName -eq $VMName)
            {
                Write-Verbose "OK. The adapter is connected to the right VM"       
            }
            else
            {
                Write-Verbose "NOK. The adapter is conected to the wrong VM"
                return $false
            }
        }
            
        if($PSBoundParameters.ContainsKey('VLAN'))
        {
            Write-Verbose "Checking VLAN configuration..."

            if($vNIC.VLAN -eq $VLAN)
            {
                Write-Verbose "OK. The correct VLAN tag is configured."
            }
            else
            {
                Write-Verbose "NOK. The VLAN settings are not correct."
                return $false
            }
        }

        if($PSBoundParameters.ContainsKey('MinimumBandwidthWeight'))
        {
            Write-Verbose "Checking MinimumBandwidthWeight QoS settings..."
            
            if($vNIC.MinimumBandwidthWeight -eq $MinimumBandwidthWeight)
            {
                Write-Verbose "OK the MinimumBandwidthWeight setting is correctly configured"
            }
            else
            {
                Write-Verbose "NOK. the MinimumBandwidthWeight setting is not correctly configured."
                return $false
            }
        }

        #OK. The VMNetworkAdapter should be present, is present and has the right settings.
        Write-Verbose "OK. The configuration of the vNIC `"$vNICName`" is in desired state."
        return $true
    }

    #NOK. vNIC is Absent but should be Present
    if(($vNIC.Ensure -eq 'Absent') -and ($Ensure -eq 'Present'))
    {
        return $false
    }

    #NOK. vNIC is Present but should be Absent
    if(($vNIC.Ensure -eq 'Present') -and ($Ensure -eq 'Absent'))
    {
        return $false
    }

    #OK. vNIC is Absent and should be Absent
    if(($vNIC.Ensure -eq 'Absent') -and ($Ensure -eq 'Absent'))
    {
        return $true
    }
}


Export-ModuleMember -Function *-TargetResource
