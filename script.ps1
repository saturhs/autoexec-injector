Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[int]$windowHeight = 400
[int]$windowWidth = 400

# WINDOW CREATION
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Autoexec injector"
$Form.Size = New-Object System.Drawing.Size($windowWidth, $windowHeight)

# STATUS LABEL CREATION
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.BackColor = "Transparent"
$statusLabel.Font = New-Object System.Drawing.Font('Consolas', 12, [System.Drawing.FontStyle]::Bold)
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(10, 10)
$statusLabel.Text = "Status:"

####
$librarypath = New-Object System.Windows.Forms.TextBox
#$librarypath.Multiline = $true
$librarypath.ReadOnly = $true
$librarypath.TabStop = $false
$librarypath.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$librarypath.BackColor = $Form.BackColor
$librarypath.Size = New-Object System.Drawing.Size(380, 100)
$librarypath.Location = New-Object System.Drawing.Point(250, 40)
$librarypath.Font = New-Object System.Drawing.Font('Consolas', 12)
$librarypath.Text = "Status: Proszę czekać..." # Tekst początkowy
####


# Tworzenie TextBox jako etykiety
$status = New-Object System.Windows.Forms.TextBox
$status.Multiline = $true
$status.ReadOnly = $true
$status.TabStop = $false # Wyłączenie kursora w TextBox
$status.BorderStyle = [System.Windows.Forms.BorderStyle]::None # Brak obramowania
$status.BackColor = $Form.BackColor # Dopasowanie tła do formularza
$status.Size = New-Object System.Drawing.Size(380, 100)
$status.Location = New-Object System.Drawing.Point(10, 40)
$status.Font = New-Object System.Drawing.Font('Consolas', 12)
$status.Text = "Czekam na ścieżkę..." # Tekst początkowy

# Warunek: jeśli $cs2path istnieje
if ($cs2path) {
    # Zaktualizuj TextBox i wyświetl w konsoli
    $status.Text = $cs2path
    Write-Host "Scieżka do CS:GO: $cs2path"
} else {
    # Jeśli nie ma ścieżki, wyświetl komunikat o błędzie
    $status.Text = "Nie znaleziono sciezki do CS:GO"
    Write-Host "Nie znaleziono CS:GO w bibliotekach Steam."
}

$button = New-Object System.Windows.Forms.Button
$button.Text = "Wybierz plik autoexec..."
$button.Size = New-Object System.Drawing.Size(150, 30)
$button.Location = New-Object System.Drawing.Point(200, 200)

# Otwieranie pliku autoexec
$button.Add_Click({
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $env:USERPROFILE+"\Downloads"
    $OpenFileDialog.Filter = "Config files (*.cfg) | *.cfg"
    $OpenFileDialog.Title = "Wybierz plik cfg"

    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        [System.Windows.Forms.MessageBox]::Show("Wybrano plik: " + $OpenFileDialog.FileName)
        $autoexecPath = $OpenFileDialog.FileName
        InjectAutoexec
        return $autoexecPath
    }
})


# Funkcja do pobrania ścieżki Steam z rejestru
function Get-SteamInstallPath {
    $registeryPath = "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
    $installPath = (Get-ItemProperty -Path $registeryPath -Name InstallPath -ErrorAction SilentlyContinue).InstallPath
    if ($installPath) {
        $libraryFoldersPath = Join-Path -Path $installPath -ChildPath "steamapps\libraryfolders.vdf"
        $librarypath.Text = "Ścieżka do bibliotek Steam: $libraryFoldersPath"
        return $libraryFoldersPath
    } else {
        $librarypath.Text = "Błąd: Nie znaleziono Steam."
        return ""
    }
}

# Funkcja do znalezienia ścieżki do gry CS:GO (AppID 730)
function Get-CSGOPath {
    param (
        [string]$libraryFoldersPath
    )

    # Sprawdź, czy plik libraryfolders.vdf istnieje
    if (-not (Test-Path -Path $libraryFoldersPath)) {
        Write-Host "Błąd: Plik $libraryFoldersPath nie istnieje." -ForegroundColor Red
        return $null
    }
    
    Write-Host "Przetwarzam plik libraryfolders.vdf: $libraryFoldersPath"

    $cs2path = $null
    $pathRegex = '"path"\s+"(.+?)"'
    $appRegex = '"730"\s+".+?"'
    $currentPath = $null # Zmienna tymczasowa do przechowywania ścieżki

    try {
        $fileContent = Get-Content -Path $libraryFoldersPath
        Write-Host "debug 111"
    } catch {
        Write-Host "Błąd: Nie udało się odczytać pliku $libraryFoldersPath. Szczegóły: $_" -ForegroundColor Red
        return $null
    }

    foreach ($line in $fileContent) {
        # Znajdź linie ze ścieżką biblioteki
        if ($line -match $pathRegex) {
            $currentPath = $matches[1] # Przypisz ścieżkę
        }
        # Znajdź linie z AppID gry 730 w sekcji "apps"
        elseif ($line -match $appRegex -and $currentPath) {
            # Jeśli znaleziono grę, zbuduj ścieżkę do katalogu CS:GO #TODO
            $cs2path = "$currentPath\common\Counter-Strike Global Offensive\game\core\cfg" -replace "\\\\", "\\"
            Write-Host "Znaleziono ścieżkę do CS:GO: $cs2path" -ForegroundColor Green
            break
        }
    }

    # Walidacja końcowa: jeśli $cs2path jest wciąż $null
    if (-not $cs2path) {
        Write-Host "Błąd: Nie znaleziono gry o ID 730 w bibliotekach Steam." -ForegroundColor Yellow
    }

    return $cs2path
}



# Uruchom funkcję Get-SteamInstallPath i, jeśli znajdzie ścieżkę, uruchom Get-CSGOPath
$libraryFoldersPath = Get-SteamInstallPath
if ($libraryFoldersPath) {
    $cs2path = Get-CSGOPath -libraryFoldersPath $libraryFoldersPath
    if ($cs2path) {
        Write-Host "Ścieżka do CS:GO: $cs2path"
    } else {
        Write-Host "Nie znaleziono CS:GO w bibliotekach Steam."
    }
}

function InjectAutoexec {
    param (
        [string]$autoexecPath,
        [string]$cs2path
    )

    # Sprawdzenie, czy oba parametry są prawidłowe
    if (-not $autoexecPath -or -not $cs2path) {
        Write-Host "Błąd: Brakuje ścieżki do pliku lub CS:GO." -ForegroundColor Red
        return
    }

    # Sprawdzenie, czy podana ścieżka do autoexec istnieje
    if (Test-Path $autoexecPath) {
        $autoexecContent = Get-Content $autoexecPath
        if ($autoexecContent) {
            # Cel przeniesienia: folder CS:GO
            $destinationPath = Join-Path -Path $cs2path -ChildPath "cfg\autoexec.cfg"

            # Sprawdzenie, czy folder docelowy istnieje
            if (-not (Test-Path -Path (Join-Path -Path $cs2path -ChildPath "cfg"))) {
                Write-Host "Folder 'cfg' w CS:GO nie istnieje. Tworzę go..." -ForegroundColor Yellow
                New-Item -ItemType Directory -Path (Join-Path -Path $cs2path -ChildPath "cfg") | Out-Null
            }

            # Przeniesienie pliku
            try {
                Move-Item -Path $autoexecPath -Destination $destinationPath -Force
                Write-Host "Plik został pomyślnie przeniesiony do: $destinationPath" -ForegroundColor Green
            } catch {
                Write-Host "Błąd: Nie udało się przenieść pliku. Szczegóły: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Plik $autoexecPath jest pusty lub nie można go odczytać." -ForegroundColor Red
        }
    } else {
        Write-Host "Błąd: Plik $autoexecPath nie istnieje." -ForegroundColor Red
    }
}


# Dodanie elementów do formularza
#$Form.Controls.Add($button)
Test-Path "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf"
$Form.Controls.Add($status)
$Form.Controls.Add($librarypath)
$Form.Controls.Add($statusLabel)
$Form.Controls.Add($button)
#InjectAutoexec
$cs2path = $cs2path -replace "\\\\", "\\"
Write-Host "Ścieżka do CS:GO: $cs2path"

$Form.ShowDialog()
