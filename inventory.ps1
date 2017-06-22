# inventory.ps1
# Joe Goyette (jgoyette@vmware.com)
# V1.0 June 21, 2017

<#
.SYNOPSIS

Collect VM and Host inventory for named vCenter Server system
.DESCRIPTION

Collect VM and Host inventory for named vCenter Server system.
#>


$vuser = "administrator@vsphere.local"
$vpass = "VMware1!"
$vserver = "vc65.vmguitarlab.com"
$vmcsv = "C:\tmp\vms.csv"
$hostcsv = "C:\tmp\hosts.csv"
$clustercsv = "C:\tmp\clusters.csv"

Connect-VIServer $vserver -user $vuser -password $vpass

# Collect the VM inventory
Write-Host ""
Write-Host "Collecting VM Inventory"
$vminventory = Get-VM | Select @{N="Datacenter";E={Get-Datacenter -VM $_}}, `
  @{N="Cluster";E={Get-Cluster -VM $_}},VMHost, Name, NumCpu, MemoryMB, GuestId, `
  UsedSpaceGB, ProvisionedSpaceGB,  @{N="VMDK Count";E={(Get-HardDisk -VM $_).Count}}, `
  @{N="Snapshot Count";E={(Get-Snapshot -VM $_).Count}}
Write-Host "Collected inventory for $($vminventory.Count) VMs"
Write-Host "Saving VM output to $vmcsv"
$vminventory | Export-Csv $vmcsv -force -notypeinformation


# Collect the Host inventory
Write-Host ""
Write-Host "Collecting Host Inventory"
$hostinventory = Get-VMHost | Select @{N="Datacenter";E={Get-Datacenter -VMHost $_}}, `
  @{N="Cluster";E={Get-Cluster -VMHost $_}}, Name, PowerState, Manufacturer, Model,NumCpu, `
  @{N="CPU Packages"; E={(Get-View $_).Hardware.Cpuinfo.NumCpuPackages}}, @{N="CPU Cores"; `
  E={(Get-View $_).Hardware.Cpuinfo.NumCpuCores}},  HyperThreadingActive, `
  CpuTotalMhz, CpuUsageMhz, MemoryTotalGB, MemoryUsageGB, Version, Build, `
  @{N="vCPU Count";E={Get-VM -Location $_ | Measure-Object -Property NumCpu -Sum | Select -ExpandProperty Sum}}, `
  @{N="VM Count";E={(Get-VM -Location $_).Count}}
Write-Host "Collected inventory for $($hostinventory.Count) Hosts"
Write-Host "Saving Host output to $hostcsv"
$hostinventory | Export-Csv $hostcsv -force -notypeinformation


# Collect the Cluster inventory
Write-Host ""
Write-Host "Collecting Cluster Inventory"
$clusterinventory = Get-Cluster | Select Name, @{N="Host Count"; E={(Get-View $_).Host.Count}}, `
   @{N="VM Count";E={Get-VM -Location $_ | Measure-Object -Property NumCpu -Sum | Select -ExpandProperty Sum}}, `
   @{N="Datastore Count"; E={(Get-View $_).Datastore.Count}},
   @{N="CPU Demand"; E={(Get-View $_).Summary.UsageSummary.CpuDemandMhz}}, `
   @{N="CPU Capacity "; E={(Get-View $_).Summary.UsageSummary.TotalCpuCapacityMhz}},
   @{N="Memory Demand"; E={(Get-View $_).Summary.UsageSummary.MemDemandMB}},
   @{N="Memory Capacity"; E={(Get-View $_).Summary.UsageSummary.TotalMemCapacityMB}}
Write-Host "Collected inventory for $($clusterinventory.Count) Clusters"
Write-Host "Saving Cluster output to $clustercsv"
$clusterinventory | Export-Csv $clustercsv -force -notypeinformation
