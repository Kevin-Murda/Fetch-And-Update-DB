#!/usr/bin/env powershell

$config = @{}

# If configure file exists, then execute it.
if (Test-Path './update-db.conf') {
    $content = Import-Csv './update-db.conf' -Delimiter '=' -Header 'key','value'

    foreach ($row in $content)
    {
        if ($row.key.StartsWith('#')) {
            continue
        }

        $config[$row.key] = $row.value.Replace("'", '').Replace('"', '')
    }
}


# Prompt user for credentials if none provided.
while ([string]::IsNullOrEmpty($config['REMOTE_USER'])) {
    $config['REMOTE_USER'] = Read-Host '> Enter username of remote server'
}

while ([string]::IsNullOrEmpty($config['REMOTE_HOST'])) {
    $config['REMOTE_USER'] = Read-Host '>  Enter host/IP of remote server'
}

while ([string]::IsNullOrEmpty($config['REMOTE_DB_USER'])) {
    $config['REMOTE_DB_USER'] = Read-Host '>  Enter username of remote database'
}
