$DebugPreference = 'Continue'

$incoming = 'incoming'
$temp1 = 'temp1'
$temp2 = 'temp2'
$output = 'output'

if (Test-Path $temp1) { del $temp1 -r }
if (Test-Path $temp2) { del $temp2 -r }

$apps = dir $incoming -Directory
$count = 0
$hasFailed = $false
$apps | foreach {
    $name = $_.Name
    Write-Progress -Activity 'Repacking apps' -PercentComplete ($count / $apps.Length * 100) -CurrentOperation $name
    echo "Repacking $name"

    md $temp1 | Out-Null
    md $temp2 | Out-Null

    # d:\sync\0day\util\7z x -o"d:\sync\0day\temp1" "d:\sync\0day\incoming\VanDyke.SecureCRT.v7.2.2.491.Incl.Patch.And.Keymaker-ZWT\*.zip"
    $arguments = 'x', "-o""$temp1""", '-y', (Join-Path $_.FullName *.zip)
    util\7z.exe $arguments | Out-Null

    if (!$?) {
        Write-Warning "Repacking $name failed."
        echo "$name" >> "$output\fail.log"

        del $temp1 -r
        del $temp2 -r

        $count++
        $hasFailed = $true
        return
    }

    # d:\sync\0day\util\7z x -o"d:\sync\0day\temp2" "d:\sync\0day\temp1\*.rar" -y
    #$arguments = 'x', "-o""$temp2""", '-y', "$temp1\*.rar"
    #.\7z.exe $arguments | Out-Null
    $arguments = 'x', "-y", "$temp1\\*.*", "$temp2"
    util\Rar.exe $arguments | Out-Null
    if (!$?) {
        Write-Warning "Repacking $name failed."
        echo "$name" >> "$output\fail.log"

        del $temp1 -r
        del $temp2 -r

        $count++
        $hasFailed = $true
        return
    }

    # copy d:\sync\0day\temp1\*.diz d:\sync\0day\temp2
    # copy d:\sync\0day\temp1\*.nfo d:\sync\0day\temp2

    dir $temp1 | where {
        $_.Extension -notmatch 'rar|r\d*'
    } | copy -Destination $temp2

    #d:\sync\0day\util\7z a "d:\sync\0day\output\VanDyke.SecureCRT.v7.2.2.491.Incl.Patch.And.Keymaker-ZWT.zip" "d:\sync\0day\temp2\*.*" -r
    $arguments = 'a', "$output\$name.zip", "$temp2\*.*", '-r'
    util\7z $arguments | Out-Null
    if (!$?) {
        Write-Warning "Repacking $name failed."
        echo "$name" >> "$output\fail.log"

        del $temp1 -r
        del $temp2 -r

        $count++
        $hasFailed = $true
        return
    }

    del $temp1 -r
    del $temp2 -r

    Remove-Item -LiteralPath $_.FullName -r

    $count++
}

Write-Progress -Activity 'Repacking apps' -Completed

if ($hasFailed) {
    echo '' >> "$output\fail.log"
}

echo 'Press any key to continue...'
[Console]::ReadKey() | Out-Null

# del 'd:\sync\0day\output\*.*' -r