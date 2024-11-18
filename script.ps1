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



# Tworzenie TextBox jako etykiety
$steamLibraryTextbox = New-Object System.Windows.Forms.TextBox
$steamLibraryTextbox.Multiline = $true
$steamLibraryTextbox.ReadOnly = $true
$steamLibraryTextbox.TabStop = $false # Wyłączenie kursora w TextBox
$steamLibraryTextbox.BorderStyle = [System.Windows.Forms.BorderStyle]::None # Brak obramowania
$steamLibraryTextbox.BackColor = $Form.BackColor # Dopasowanie tła do formularza
$steamLibraryTextbox.Size = New-Object System.Drawing.Size(380, 100)
$steamLibraryTextbox.Location = New-Object System.Drawing.Point(10, 90)
$steamLibraryTextbox.Font = New-Object System.Drawing.Font('Consolas', 12)
$steamLibraryTextbox.Text = "Please wait..." # Tekst początkowy

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
$status.Text = "Please wait..." # Tekst początkowy

$chosenFileLabel = New-Object System.Windows.Forms.Label
$chosenFileLabel.Text = "Wybrany plik: $autoexecPath"
$chosenFileLabel.Location = New-Object System.Drawing.Point(10, 200)
$chosenFileLabel.Size = New-Object System.Drawing.Size(180, 40)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Wybierz plik autoexec..."
$button.Size = New-Object System.Drawing.Size(150, 30)
$button.Location = New-Object System.Drawing.Point(200, 200)

# Otwieranie pliku autoexec
$button.Add_Click({
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $env:USERPROFILE+"\Downloads"
    $OpenFileDialog.Filter = "Config files (*.cfg) | *.cfg"
    $OpenFileDialog.Title = "Chose cfg file"

    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        [System.Windows.Forms.MessageBox]::Show("Wybrano plik: " + $OpenFileDialog.FileName)
        $global:autoexecPath = $OpenFileDialog.FileName
        Write-Host "Chosen file: $autoexecPath"
        Write-Host "Chosen CS:GO folder: $cs2path"
        $Form.Controls.Add($chosenFileLabel)
        return $autoexecPath
    }
})
function InjectAutoexec {
    param (
        [string]$autoexecPath,
        [string]$cs2path
    )

    # Sprawdzenie, czy oba parametry są prawidłowe
    if (-not $autoexecPath -or -not $cs2path) {
        Write-Host "Error: Both cfg file and CS:GO folder path must be provided." -ForegroundColor Red
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
                Write-Host "Folder cfg does not exist, creating one... " -ForegroundColor Yellow
                New-Item -ItemType Directory -Path (Join-Path -Path $cs2path -ChildPath "cfg") | Out-Null
            }

            # Przeniesienie pliku
            try {
                Copy-Item -Path $autoexecPath -Destination $destinationPath -Force
                Write-Host "File was successfully copied to: $destinationPath" -ForegroundColor Green
            } catch {
                Write-Host "Error copying file, details: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "File $autoexecPath is empty and cannot be processed." -ForegroundColor Red
        }
    } else {
        Write-Host "Error: File $autoexecPath does not exist." -ForegroundColor Red
    }
}


# Funkcja do pobrania ścieżki Steam z rejestru
function Get-SteamInstallPath {
    $registeryPath = "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
    $installPath = (Get-ItemProperty -Path $registeryPath -Name InstallPath -ErrorAction SilentlyContinue).InstallPath
    if ($installPath) {
        $libraryFoldersPath = Join-Path -Path $installPath -ChildPath "steamapps\libraryfolders.vdf"
        Write-Host "cwel jebany es"
        $index = $libraryFoldersPath.IndexOf("Steam")
        $steamPath = $libraryFoldersPath.Substring(0, $index + "Steam".Length)
        $steamLibraryTextbox.Text = "Steam path: " + $steamPath
        return $libraryFoldersPath
    } else {
        $librarypath.Text = "Status: Not found"
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
            $cs2path = Join-Path -Path $currentPath -ChildPath "common\Counter-Strike Global Offensive"
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
        $status.Text = "Sciezka do CS:GO: $cs2path"
        Write-Host "Sciezka do CS:GO: $cs2path"
    } else {
        $status.Text = "Nie znaleziono sciezki do CS:GO"
        Write-Host "Nie znaleziono CS:GO w bibliotekach Steam."
    }
}

$buttonExecute = New-Object System.Windows.Forms.Button
$buttonExecute.Text = "Go"
$buttonExecute.Size = New-Object System.Drawing.Size(150, 30)
$buttonExecute.Location = New-Object System.Drawing.Point(150, 150)

$buttonExecute.Add_Click({
    InjectAutoexec -autoexecPath $autoexecPath -cs2path $cs2path
})

# Dodanie elementów do formularza
$Form.Controls.Add($buttonExecute)
$Form.Controls.Add($steamLibraryTextbox)
$Form.Controls.Add($statusLabel)
$Form.Controls.Add($status)
$Form.Controls.Add($button)

$Form.ShowDialog()
