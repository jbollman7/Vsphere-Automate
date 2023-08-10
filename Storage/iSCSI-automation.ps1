# Enabling an iSCSI software adapter for all hosts in a cluster
function SetClusterIscsi {
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
