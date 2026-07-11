$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$installDir = "$env:LOCALAPPDATA\EpsilonCLI"
$exePath = "$installDir\epsilon.exe"
$downloadUrl = "https://raw.githubusercontent.com/Mimitokox/epsiloncli-files/main/cli.exe"

$localExePath = ""
if ($PSScriptRoot) {
    $localExePath = Join-Path $PSScriptRoot "prod\epsilon.exe"
    if (-not (Test-Path $localExePath)) {
        $localExePath = Join-Path $PSScriptRoot "prod\cli.exe"
    }
}
if (-not $localExePath -or -not (Test-Path $localExePath)) {
    if (Test-Path "prod\epsilon.exe") {
        $localExePath = (Resolve-Path "prod\epsilon.exe").Path
    } elseif (Test-Path "prod\cli.exe") {
        $localExePath = (Resolve-Path "prod\cli.exe").Path
    }
}

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "   ▐▛███▜▌    " -NoNewline -ForegroundColor White
    Write-Host "Epsilon CLI" -ForegroundColor Gray
    Write-Host "  ▝▜█████▛▘   " -NoNewline -ForegroundColor White
    Write-Host "Instalator - Windows" -ForegroundColor DarkGray
    Write-Host "    ▘▘ ▝▝" -ForegroundColor White
    Write-Host ""
    Write-Host "  ------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Step {
    param([string]$Text)
    Write-Host "  > " -NoNewline -ForegroundColor White
    Write-Host $Text -ForegroundColor Gray
}

function Write-Ok {
    param([string]$Text)
    Write-Host "  + " -NoNewline -ForegroundColor White
    Write-Host $Text -ForegroundColor Gray
}

function Write-Fail {
    param([string]$Text)
    Write-Host "  ! " -NoNewline -ForegroundColor White
    Write-Host $Text -ForegroundColor DarkGray
}

function Get-RemoteFile {
    param([string]$Url, [string]$Destination)

    $bust = [Guid]::NewGuid().ToString("N")
    if ($Url.Contains("?")) {
        $Url = "$Url&t=$bust"
    } else {
        $Url = "$Url`?t=$bust"
    }

    $request = [System.Net.HttpWebRequest]::Create($Url)
    $request.UserAgent = "EpsilonCLI-Installer"
    $request.Timeout = 30000
    $request.CachePolicy = New-Object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::NoCacheNoStore)
    $request.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
    $request.Headers.Add("Pragma", "no-cache")
    $response = $request.GetResponse()
    $totalBytes = [double]$response.ContentLength
    $responseStream = $response.GetResponseStream()
    $fileStream = [System.IO.File]::Create($Destination)

    $buffer = New-Object byte[] 262144
    $downloaded = [double]0
    $barWidth = 30
    $lastPct = -1

    try {
        while (($bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $fileStream.Write($buffer, 0, $bytesRead)
            $downloaded += $bytesRead

            if ($totalBytes -gt 0) {
                $pct = [int](($downloaded / $totalBytes) * 100)
                if ($pct -ne $lastPct) {
                    $lastPct = $pct
                    $filled = [int](($downloaded / $totalBytes) * $barWidth)
                    $empty = $barWidth - $filled
                    Write-Host "`r  [" -NoNewline -ForegroundColor DarkGray
                    Write-Host ([string]([char]0x2588) * $filled) -NoNewline -ForegroundColor White
                    Write-Host ([string]([char]0x2591) * $empty) -NoNewline -ForegroundColor DarkGray
                    Write-Host "] " -NoNewline -ForegroundColor DarkGray
                    Write-Host ("{0,3}%  {1,5:N1} / {2,5:N1} MB" -f $pct, ($downloaded / 1MB), ($totalBytes / 1MB)) -NoNewline -ForegroundColor Gray
                }
            }
        }
    } finally {
        $fileStream.Close()
        $responseStream.Close()
        $response.Close()
    }
    Write-Host ""
}

Show-Header

$sourceLocal = $false
if ($localExePath -and (Test-Path $localExePath)) {
    Write-Step "Wykryto lokalna kompilacje: $localExePath"
    $sourceLocal = $true
}

if (-not (Test-Path $installDir)) {
    Write-Step "Tworzenie katalogu: $installDir"
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}

$running = Get-Process -Name "epsilon" -ErrorAction SilentlyContinue
if ($running) {
    Write-Step "Zamykanie dzialajacego Epsilon CLI..."
    $running | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

if (Test-Path $exePath) {
    try {
        Remove-Item -Path $exePath -Force -ErrorAction Stop
    } catch {
        Write-Fail "Nie mozna usunac starej wersji - zamknij Epsilon CLI i sprobuj ponownie."
        exit 1
    }
}

if ($sourceLocal) {
    Write-Step "Kopiowanie lokalnego pliku..."
    Copy-Item -Path $localExePath -Destination $exePath -Force
} else {
    Write-Step "Pobieranie Epsilon CLI..."
    Write-Host ""
    try {
        Get-RemoteFile -Url $downloadUrl -Destination $exePath
    } catch {
        Write-Host ""
        Write-Fail "Blad pobierania pliku!"
        Write-Fail $_.Exception.Message
        exit 1
    }
    Write-Host ""
}

if (Test-Path $exePath) {
    $size = (Get-Item $exePath).Length / 1MB
    Write-Ok ("Zapisano: $exePath ({0:N2} MB)" -f $size)
} else {
    Write-Fail "Nie znaleziono pliku epsilon.exe po instalacji!"
    exit 1
}

Write-Step "Konfiguracja PATH..."
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$installDir*") {
    $newPath = $userPath
    if (-not $newPath.EndsWith(';')) {
        $newPath += ';'
    }
    $newPath += $installDir
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    $env:PATH = "$env:PATH;$installDir"
    Write-Ok "Dodano $installDir do PATH."
} else {
    Write-Ok "Sciezka jest juz w PATH."
}

Write-Host ""
Write-Host "  ------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  + " -NoNewline -ForegroundColor White
Write-Host "Epsilon CLI zainstalowany pomyslnie!" -ForegroundColor Gray
Write-Host ""
Write-Host "    Otworz NOWY terminal i wpisz:" -ForegroundColor DarkGray
Write-Host "      epsilon" -NoNewline -ForegroundColor White
Write-Host "  lub  " -NoNewline -ForegroundColor DarkGray
Write-Host "epsilon settings" -ForegroundColor White
Write-Host ""
