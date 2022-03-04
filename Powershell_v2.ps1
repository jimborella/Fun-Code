#Milestone Challenge

#Parameters
#[Service Principal AuthN/Z]
$tnt_id = '9b3a32f3-18cf-4dcb-81c8-046ae08aac69'
$app_id = '4b991bc7-3511-47e9-a397-7dd5835eed83'
$certTP = '114468ceceb94ededc40fd38405d818220786db2'
#[Resource]
$rg_name = 'Milestone-Challenege-PYPS'
#[VM Config]
$VM_Image_PubID = 'canonical'
$VM_Image_PRODID = '0001-com-ubuntu-server-focal'
$vm_image_sku = '20_04-lts-gen2'
$Num_cores = 2
$Num_Mem = 2048
#[SSH Config]
$path_to_ssh = 'C:\Users\CDW\.ssh\'

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#Connect to Azure Service Principal (Powershell SP)
Connect-AzAccount -ServicePrincipal -Tenant $tnt_id -ApplicationId $app_id -CertificateThumbprint $certTP
$Found_RG = Get-AzResourceGroup -Name $rg_name

#Networking
#[NSG]
$rstype = 'NSG'; $rsname = 'MSC_PYPW' ; $name_gen = ($rstype + '-' + $rsname + '-' + $Found_RG.Location)
$new_NSG_rule = New-AzNetworkSecurityRuleConfig `
    -Name SSH-Allow `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22
$new_NSG = New-AzNetworkSecurityGroup -Name $name_gen -ResourceGroupName $Found_RG.ResourceGroupName -Location $Found_RG.Location `
    -SecurityRules $new_NSG_rule `
    -Force

    #[Subnets]
$rstype = 'Subnet'; $name_gen = ($rstype + '-' + $rsname + '-' + $Found_RG.Location)
$new_subnet = New-AzVirtualNetworkSubnetConfig -Name $name_gen `
    -AddressPrefix "10.0.1.0/24" `
    -NetworkSecurityGroup $new_NSG

    #[Vnet]
$rstype = 'Vnet'; $name_gen = ($rstype + '-' + $rsname + '-' + $Found_RG.Location)
$new_vnet = New-AzVirtualNetwork `
    -name $name_gen -ResourceGroupName $Found_RG.ResourceGroupName -Location $Found_RG.Location `
    -AddressPrefix '10.0.0.0/8' `
    -Subnet $new_subnet `
    -Force

#Compute
#[VM-Size-Eval] Finds size Available, assigns to VM.
$Avail_vm_sizes = Get-AzVMSize -Location $Found_RG.Location | where-object { ($_.numberofcores -LE $Num_cores) -and ($_.MemoryInMB -LE $Num_Mem) }
$max_mem = ($Avail_vm_sizes | Measure-Object -Property MemoryInMB -Maximum).Maximum
if ((($Avail_vm_sizes | Where-Object { $_.MemoryInMB -eq $max_mem }).count) -gt 1) {foreach ($size in ($Avail_vm_sizes | Where-Object { $_.MemoryInMB -eq $max_mem })) { $vm_size = $size; break }}
else{$vm_size = ($Avail_vm_sizes | Where-Object { $_.MemoryInMB -eq $max_mem})}
$vm_size

#[VM-Config]
$rstype = 'VM'; $name_gen = ($rstype + '-' + $rsname + '-' + $Found_RG.Location)
$new_VM = New-AzVMConfig -VMName $name_gen -VMSize $vm_size.Name

#[VM-OS/Image]
Write-warning "Requires User Credentials"; $user_cred = Get-Credential
$rstype = 'VM'; $rsname = 'MSCPYPW'; $name_gen = ($rstype + '-' + $rsname + '-' + $Found_RG.Location)
$new_vm = Set-AzVMOperatingSystem -vm $new_VM -Linux -ComputerName $name_gen -Credential $user_cred
$new_VM = Set-AzVMSourceImage -vm $new_vm -Version 'latest' -PublisherName $VM_Image_PubID -Offer $VM_Image_PRODID -Skus $vm_image_sku

#[VM-Net]
$rstype = 'PubIP'; $name_gen = ($rstype + '-' + $rsname + '-' + $Found_RG.Location)
$new_pubip = New-AzPublicIpAddress -Name $name_gen -ResourceGroupName $Found_RG.ResourceGroupName -Location $Found_RG.Location -AllocationMethod Dynamic -IpAddressVersion IPv4 -Force -warningAction 'SilentlyContinue'
$rstype = 'vNIC'; $name_gen = ($rstype + '-' + $rsname + '-' + $Found_RG.Location)
$new_vm = New-AzNetworkInterface -Name $name_gen -ResourceGroupName $Found_RG.ResourceGroupName -Location $Found_RG.Location -SubnetId $new_vnet.Subnets.id -PublicIpAddressId $new_pubip.Id -Force | Add-AzVMNetworkInterface -vm $new_VM

#[VM-Build]
$rstype = 'SSHKey'; $name_gen = ($rstype + '-' + $rsname + '-' + $Found_RG.Location)
new-azvm -ResourceGroupName $Found_RG.ResourceGroupName -Location $Found_RG.Location -vm $new_VM -GenerateSshKey -SshKeyName $name_gen -warningAction 'SilentlyContinue'

#[Auto SSH - Prep]
Start-Service ssh-agent -ErrorAction SilentlyContinue
$path_to_Prvkey = Get-ChildItem -Path $path_to_ssh -Exclude '*.pub','config','known_hosts'
ssh-add $path_to_Prvkey
Get-ChildItem -Path $path_to_ssh -Exclude 'config','known_hosts' | Remove-Item -Force

#[Gets Public IP]
$live_ip = ($new_pubip | Get-AzPublicIpAddress).IpAddress

#[Auto SSH Session]
$ssh_string = $user_cred.UserName + '@' + $live_ip
ssh $ssh_string