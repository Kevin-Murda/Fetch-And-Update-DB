#!/usr/bin/env powershell

# If configure file exists, then execute it.
if (Test-Path './update-db.conf') {
    $content = Import-Csv './update-db.conf' -Delimiter '=' -Header 'key','value'
    $config = @{}

    foreach ($row in $content)
    {
        if ($row.key.StartsWith('#')) {
            continue
        }

        $config[$row.key] = $row.value
    }
}
