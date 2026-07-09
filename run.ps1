# EpsilonCLI - Skrypt Instalacyjny
# Użycie (lokalne): powershell -ExecutionPolicy Bypass -File run.ps1
# Użycie (z internetu): irm https://raw.githubusercontent.com/Mimitokox/epsiloncli-files/main/run.ps1 | iex

$ErrorActionPreference = 'Stop'

# Konfiguracja
$installDir = "$env:LOCALAPPDATA\EpsilonCLI"
$exePath = "$installDir\epsilon.exe"
$downloadUrl = "https://raw.githubusercontent.com/Mimitokox/epsiloncli-files/main/cli.exe"

# Ustalanie ścieżki do lokalnej kompilacji
$localExePath = ""
if ($PSScriptRoot) {
    $localExePath = Join-Path $PSScriptRoot "prod\epsilon.exe"
    if (-not (Test-Path $localExePath)) {
        $localExePath = Join-Path $PSScriptRoot "prod\cli.exe"
    }
}
# Jeśli nadal nie znaleziono, sprawdź relatywnie do bieżącego katalogu
if (-not $localExePath -or -not (Test-Path $localExePath)) {
    if (Test-Path "prod\epsilon.exe") {
        $localExePath = (Resolve-Path "prod\epsilon.exe").Path
    } elseif (Test-Path "prod\cli.exe") {
        $localExePath = (Resolve-Path "prod\cli.exe").Path
    }
}

# Funkcja rysująca nagłówek
function Show-Header {
    Clear-Host
    Write-Host "  ▐▛███▜▌   Epsilon CLI - Instalator" -ForegroundColor Cyan
    Write-Host "  ▝▜█████▛▘  System: Windows" -ForegroundColor Cyan
    Write-Host "    ▘▘ ▝▝" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Gray
}

Show-Header

# Ustalanie źródła instalacji
$sourceLocal = $false
if ($localExePath -and (Test-Path $localExePath)) {
    Write-Host "[*] Wykryto lokalną kompilację w: $localExePath" -ForegroundColor Yellow
    $sourceLocal = $true
}

# Tworzenie katalogu docelowego
if (-not (Test-Path $installDir)) {
    Write-Host "[*] Tworzenie katalogu instalacyjnego: $installDir..." -ForegroundColor DarkGray
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}

# Kopiowanie lub pobieranie pliku EXE
if ($sourceLocal) {
    Write-Host "[*] Kopiowanie lokalnego pliku EXE..." -ForegroundColor Yellow
    Copy-Item -Path $localExePath -Destination $exePath -Force
} else {
    Write-Host "[*] Pobieranie pliku EXE z $downloadUrl..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath -UseBasicParsing
    } catch {
        Write-Host "[-] Błąd pobierania pliku Epsilon CLI!" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
}

# Sprawdzenie czy plik istnieje i jest poprawny
if (Test-Path $exePath) {
    $size = (Get-Item $exePath).Length / 1MB
    Write-Host ("`n[+] Pomyślnie zapisano plik: $exePath ({0:N2} MB)" -f $size) -ForegroundColor Green
} else {
    Write-Host "[-] Krytyczny błąd: Nie znaleziono pliku epsilon.exe po instalacji!" -ForegroundColor Red
    exit 1
}

# Dodawanie do PATH
Write-Host "[*] Konfiguracja zmiennych środowiskowych PATH..." -ForegroundColor DarkGray
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($userPath -notlike "*$installDir*") {
    $newPath = $userPath
    if (-not $newPath.EndsWith(';')) {
        $newPath += ';'
    }
    $newPath += $installDir
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    # Aktualizacja PATH dla bieżącej sesji PowerShell
    $env:PATH = "$env:PATH;$installDir"
    Write-Host "[+] Dodano $installDir do PATH użytkownika." -ForegroundColor Green
} else {
    Write-Host "[*] Ścieżka $installDir jest już obecna w PATH." -ForegroundColor DarkGray
}

Write-Host "==========================================" -ForegroundColor Gray
Write-Host "[+] Epsilon CLI został pomyślnie zainstalowany!" -ForegroundColor Green
Write-Host ""
Write-Host "    Aby zacząć korzystać, otwórz NOWY terminal i wpisz:" -ForegroundColor Cyan
Write-Host "    epsilon" -ForegroundColor Yellow -NoNewline
Write-Host " lub " -ForegroundColor White -NoNewline
Write-Host "epsilon settings" -ForegroundColor Yellow
Write-Host ""
Write-Host "==========================================" -ForegroundColor Gray
