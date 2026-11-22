[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$getResp = Invoke-RestMethod -Uri 'https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/global_config/devices_master' -Method Get

$existingDevices = $getResp.fields.devices.arrayValue.values

# Check if s26_new already exists
$found = $false
foreach ($d in $existingDevices) {
    if ($d.mapValue.fields.id.stringValue -eq "s26_new") {
        $found = $true
        break
    }
}

$s26NewItem = @{
    mapValue = @{
        fields = @{
            id = @{ stringValue = "s26_new" }
            name = @{ stringValue = "갤럭시 S26 NEW" }
            group = @{ stringValue = "S" }
            tag = @{ stringValue = "#S26" }
            prices = @{
                mapValue = @{
                    fields = @{
                        SK = @{ doubleValue = 140.36 }
                        KT = @{ doubleValue = 140.36 }
                        LG = @{ doubleValue = 140.36 }
                    }
                }
            }
            sub = @{
                mapValue = @{
                    fields = @{
                        SK = @{
                            mapValue = @{
                                fields = @{
                                    mnp = @{ integerValue = "75" }
                                    chg = @{ integerValue = "75" }
                                }
                            }
                        }
                        KT = @{
                            mapValue = @{
                                fields = @{
                                    mnp = @{ integerValue = "75" }
                                    chg = @{ integerValue = "75" }
                                }
                            }
                        }
                        LG = @{
                            mapValue = @{
                                fields = @{
                                    mnp = @{ integerValue = "75" }
                                    chg = @{ integerValue = "75" }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

$newDeviceList = @()
if ($found) {
    Write-Host "s26_new already exists, updating..."
    foreach ($d in $existingDevices) {
        if ($d.mapValue.fields.id.stringValue -eq "s26_new") {
            $newDeviceList += $s26NewItem
        } else {
            $newDeviceList += $d
        }
    }
} else {
    Write-Host "Adding s26_new right after s26..."
    foreach ($d in $existingDevices) {
        $newDeviceList += $d
        if ($d.mapValue.fields.id.stringValue -eq "s26") {
            $newDeviceList += $s26NewItem
        }
    }
}

$patchBody = @{
    fields = @{
        devices = @{
            arrayValue = @{
                values = $newDeviceList
            }
        }
    }
} | ConvertTo-Json -Depth 15

$patchResp = Invoke-RestMethod -Uri 'https://firestore.googleapis.com/v1/projects/phone-price-91c3c/databases/(default)/documents/global_config/devices_master' -Method Patch -Body $patchBody -ContentType "application/json; charset=utf-8"

Write-Host "Successfully updated Firestore devices_master with s26_new! New count: $($patchResp.fields.devices.arrayValue.values.Count)"
