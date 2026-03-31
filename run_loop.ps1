
$count = 1
while ($count -gt 0) {
    dart run fix_consts.dart > temp_out.txt
    Get-Content temp_out.txt
    if (Select-String -Path temp_out.txt -Pattern "Found 0 files") {
        $count = 0
    }
}

