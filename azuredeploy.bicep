param adminUsername string
param adminPassword string
param location string = resourceGroup().location

var vmName = 'CoD4Server-vm'
var nicName = '${vmName}-nic'
var vnetName = '${vmName}-vnet'
var subnetName = '${vmName}-subnet'
var publicIPName = '${vmName}-pip'
var nsgName = '${vmName}-nsg'

// Public IP for your Primary NIC
resource pip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
    name: publicIPName
    location: location
    properties: {
        publicIPAllocationMethod: 'Static'
    }
}

// This will be your Primary NIC
resource nic1 'Microsoft.Network/networkInterfaces@2020-06-01' = {
    name: nicName
    location: location
    properties: {
        ipConfigurations: [
            {
                name: 'ipconfig1'
                properties: {
                    subnet: {
                        id: '${vnet.id}/subnets/${subnetName}'
                    }
                    privateIPAllocationMethod: 'Static'
                    publicIPAddress: {
                        id: pip.id
                    }
                }
            }
        ]
        networkSecurityGroup: {
            id: nsg.id
        }
    }
}

// Network Security Group (NSG) for your Primary NIC
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
    name: nsgName
    location: location
    properties: {
        securityRules: [
            {
                name: 'default-allow-rdp'
                properties: {
                    priority: 1000
                    sourceAddressPrefix: '*'
                    protocol: 'Tcp'
                    destinationPortRange: '3389'
                    access: 'Allow'
                    direction: 'Inbound'
                    sourcePortRange: '*'
                    destinationAddressPrefix: '*'
                }
            }
        ]
    }
}

// This will build a Virtual Network.
resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
    name: vnetName
    location: location
    properties: {
        addressSpace: {
            addressPrefixes: [
                '10.0.0.0/16'
            ]
        }
        subnets: [
            {
                name: subnetName
                properties: {
                    addressPrefix: '10.0.1.0/24'
                    networkSecurityGroup: {
                        id: nsg.id
                    }
                }
            }
        ]
    }
}

// This is the virtual machine that you're building.
resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
    name: vmName
    location: location
    properties: {
        osProfile: {
            computerName: vmName
            adminUsername: adminUsername
            adminPassword: adminPassword
        }
        hardwareProfile: {
            vmSize: 'Standard_DS1_v2'
        }
        storageProfile: {
            imageReference: {
                publisher: 'Canonical'
                offer: 'UbuntuServer'
                sku: '18.04-LTS'
                version: 'latest'
            }
            osDisk: {
                createOption: 'FromImage'
            }
            dataDisks: []
        }
        networkProfile: {
            networkInterfaces: [
                {
                    properties: {
                        primary: true
                    }
                    id: nic1.id
                }
            ]
        }
    }
}

output publicIp string = pip.properties.ipAddress
