Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[int]$windowHeight = 400
[int]$windowWidth = 400

# WINDOW CREATION
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Autoexec injector"
$Form.Size = New-Object System.Drawing.Size($windowWidth,$windowHeight)

# LABEL CREATION
$label = New-Object System.Windows.Forms.Label
$label.BackColor = "Transparent"
$label.Font = New-Object System.Drawing.Font('Consolas',12,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10,10)

$label2 = New-Object System.Windows.Forms.Label
$label2.BackColor = "Transparent"
$label2.Font = New-Object System.Drawing.Font('Consolas',12,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$label2.AutoSize = $true
$label2.Location = New-Object System.Drawing.Point(10,30)

$label3 = New-Object System.Windows.Forms.Label
$label3.BackColor = "Transparent"
$label3.Font = New-Object System.Drawing.Font('Consolas',12,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$label3.AutoSize = $true
$label3.Location = New-Object System.Drawing.Point(10,50)

# BUTTON CREATION
$button = New-Object System.Windows.Forms.Button
$button.Text = "Wybierz plik autoexec..."
$button.Size = New-Object System.Drawing.Size(100, 30)
$button.Location = New-Object System.Drawing.Point((($windowWidth -$button.Width)/2), (($windowHeight - $button.Height)/2))

$button.Add_Click({
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $env:USERPROFILE # This PC
    $OpenFileDialog.Filter = "Config files (*.cfg) | *.cfg"
    $OpenFileDialog.Title = "Wybierz plik cfg"

    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        [System.Windows.Forms.MessageBox]::Show("Wybrano plik: " + $OpenFileDialog.FileName)
        $autoexecPath = $OpenFileDialog.FileName
        $label3.Text = "Wybrano plik: " + $autoexecPath
        return $autoexecPath
    }
})

if ($autoexecPath) {
    $label.Text = "Wybrano plik: " + $autoexecPath
}

function Get-SteamInstallPath{
    $registeryPath = "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam"
    $installPath = (Get-ItemProperty -Path $registeryPath -Name InstallPath -ErrorAction SilentlyContinue).InstallPath
    if ($installPath) {
        $label.Text = "Steam path: " + $installPath
        $libraryFoldersPath = $installPath + "\steamapps\libraryfolders.vdf"
        $label2.Text = "Library folders path: " + $libraryFoldersPath
        return $libraryFoldersPath
    } else {
        $label.Text = "Steam path: Not found"
        return ""
    }
}
Get-SteamInstallPath
$Form.Controls.Add($label2)
$Form.Controls.Add($label)
$Form.Controls.Add($label3)
$Form.Controls.Add($button)
$Form.ShowDialog()
