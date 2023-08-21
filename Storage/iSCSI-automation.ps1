# Enabling an iSCSI software adapter for all hosts in a cluster
function SetClusterIscsiAdapter {
    param(
        [string] $clusterName
    )
    try {
        $cluster = Get-Cluster $clusterName
        if (!$cluster) {
            Write-Error "Cluster '$clusterName' not found"
            return
        }

        $hosts = $cluster | Get-VMHost
        if (!$hosts) {
            Write-Error "No hosts found in cluster '$clusterName'"
            return
        }

        foreach ($host in $hosts) {
            try {
                $hostStorage = $host | Get-VMHostStorage
                if (!$hostStorage) {
                    Write-Warning "No storage found for host '$($host.Name)'"
                    continue
                }

                $hostStorage | Set-VMHostStorage -SoftwareIScsiEnabled:$true
                Write-Output "Enabled iSCSI software adapter for host '$($host.Name)'"
            } catch {
                Write-Error "An error occurred while enabling iSCSI software adapter for host '$($host.Name)': $_"
            }
        }
    } catch {
        Write-Error "An error occurred while processing cluster '$clusterName': $_"
    }
}

# Adding an iSCSI target
function AddIscsiTarget {
	param(
		[string] $clusterName,
		[string] $targetIp,
		[string] $chapName,
		[SecureString] $chapPassword
	)
	if (!$chapPassword) {
        $chapPassword = Read-Host "Enter CHAP password" -AsSecureString
	}
    try {
        $cluster = Get-Cluster $clusterName
        if (!$cluster) {
            Write-Error "Cluster '$clusterName' not found"
            return
        }

        $hosts = $cluster | Get-VMHost
        if (!$hosts) {
            Write-Error "No hosts found in cluster '$clusterName'"
            return
        }

        foreach ($host in $hosts) {
			try {
                $hbas = Get-VMHostHba -VMHost $host -Type iSCSI
                if (!$hbas) {
                    Write-Warning "No iSCSI HBAs found for host '$($host.Name)'"
                    continue
                }

                foreach ($hba in $hbas) {
                    New-IScsiHbaTarget -IScsiHba $hba -Address $targetIp -ChapType Preferred -ChapName $chapName -ChapPassword $chapPassword
                }

                Write-Output "Added iSCSI target for host '$($host.Name)'"
            } catch {
                Write-Error "An error occurred while adding iSCSI target for host '$($host.Name)': $_"
            }
        }
	} catch {
        Write-Error "An error occurred while processing cluster '$clusterName': $_"
    }
}

# This function retrieves the iSCSI HBA target for a specified cluster, iSCSI HBA device, and iSCSI HBA target address
function GetClusterIscsi {
    param(
        [string] $clusterName,
        [string] $iScsiHbaDevice,
        [string] $iScsiHbaTargetAddress
    )
    try {
        $cluster = Get-Cluster $clusterName
        if (!$cluster) {
            Write-Error "Cluster '$clusterName' not found"
            return
        }

        $hosts = $cluster | Get-VMHost
        if (!$hosts) {
            Write-Error "No hosts found in cluster '$clusterName'"
            return
        }

        foreach ($host in $hosts) {
            try {
                # Get the iSCSI HBA device
                $iScsiHba = $host | Get-VMHostHba -Type iScsi | Where-Object {$_.Device -eq $iScsiHbaDevice}
                if (!$iScsiHba) {
                    Write-Warning "iSCSI HBA device '$iScsiHbaDevice' not found for host '$($host.Name)'"
                    continue
                }

                # Get the iSCSI HBA target
                $iScsiHbaTarget = $iScsiHba | Get-IScsiHbaTarget | Where-Object {$_.Address -eq $iScsiHbaTargetAddress}
                if (!$iScsiHbaTarget) {
                    Write-Warning "iSCSI HBA target with address '$iScsiHbaTargetAddress' not found for host '$($host.Name)'"
                    continue
                }

                # Output the iSCSI HBA target information
                Write-Output "Found iSCSI HBA target with address '$iScsiHbaTargetAddress' for host '$($host.Name)'"
            } catch {
                Write-Error "An error occurred while retrieving iSCSI HBA target for host '$($host.Name)': $_"
            }
        }
    } catch {
        Write-Error "An error occurred while processing cluster '$clusterName': $_"
    }
}

# This function sets the iSCSI HBA target for a specified cluster, iSCSI HBA device, and iSCSI HBA target address
# Retrieves the specified cluster and its hosts. for each host, retrieves the specified iSCSI HBA device and its target, enbles the target with `Set-ISCSIHbaTarget`
function SetClusterIscsi {
    param(
        [string] $clusterName,
        [string] $iScsiHbaDevice,
        [string] $iScsiHbaTargetAddress
    )
    try {
        $cluster = Get-Cluster $clusterName
        if (!$cluster) {
            Write-Error "Cluster '$clusterName' not found"
            return
        }

        $hosts = $cluster | Get-VMHost
        if (!$hosts) {
            Write-Error "No hosts found in cluster '$clusterName'"
            return
        }

        foreach ($host in $hosts) {
            try {
                # Get the iSCSI HBA device
                $iScsiHba = $host | Get-VMHostHba -Type iScsi | Where-Object {$_.Device -eq $iScsiHbaDevice}
                if (!$iScsiHba) {
                    Write-Warning "iSCSI HBA device '$iScsiHbaDevice' not found for host '$($host.Name)'"
                    continue
                }

                # Get the iSCSI HBA target
                $iScsiHbaTarget = $iScsiHba | Get-IScsiHbaTarget | Where-Object {$_.Address -eq $iScsiHbaTargetAddress}
                if (!$iScsiHbaTarget) {
                    Write-Warning "iSCSI HBA target with address '$iScsiHbaTargetAddress' not found for host '$($host.Name)'"
                    continue
                }

                # Set the iSCSI HBA target
                $iScsiHbaTarget | Set-IScsiHbaTarget -Enabled:$true
                Write-Output "Enabled iSCSI HBA target with address '$iScsiHbaTargetAddress' for host '$($host.Name)'"
            } catch {
                Write-Error "An error occurred while enabling iSCSI HBA target for host '$($host.Name)': $_"
            }
        }
    } catch {
        Write-Error "An error occurred while processing cluster '$clusterName': $_"
    }
}

