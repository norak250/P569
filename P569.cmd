<# :
@echo off
set "ps_cmd=IEX (Get-Content '%~f0' | Out-String)"
powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "%ps_cmd%"
exit /b
#>

try {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $Path = Join-Path $env:USERPROFILE "Documents\PowerChat"
    if (!(Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
    $File = Join-Path $Path "chat_log.txt"
    if (!(Test-Path $File)) { "[Ready...]" | Out-File $File -Encoding utf8 }

    $WinGrey = [System.Drawing.Color]::FromArgb(212, 208, 200) # Classic 'ButtonFace'
    $WinWhite = [System.Drawing.Color]::White
    $ClassicFont = New-Object System.Drawing.Font("MS Sans Serif", 8.25)
    $ConsoleFont = New-Object System.Drawing.Font("Lucida Console", 9)

    $Form = New-Object Windows.Forms.Form
    $Form.Text = "TITLEHERE"
    $Form.Size = New-Object System.Drawing.Size(450, 550)
    $Form.BackColor = $WinGrey
    $Form.FormBorderStyle = "FixedDialog"
    $Form.MaximizeBox = $false
    $Form.StartPosition = "CenterScreen"
    $Form.TopMost = $true

    $Group = New-Object Windows.Forms.GroupBox
    $Group.Text = "Device Status"
    $Group.Location = New-Object System.Drawing.Point(10, 10)
    $Group.Size = New-Object System.Drawing.Size(415, 60)
    $Group.Font = $ClassicFont

    $LCD = New-Object Windows.Forms.Label
    $LCD.Text = "CONNECTED: ONLINE"
    $LCD.ForeColor = [System.Drawing.Color]::DarkGreen
    $LCD.Font = New-Object System.Drawing.Font("MS Sans Serif", 10, [System.Drawing.FontStyle]::Bold)
    $LCD.TextAlign = "MiddleCenter"
    $LCD.Dock = "Fill"
    $Group.Controls.Add($LCD)

    $Display = New-Object Windows.Forms.RichTextBox
    $Display.Location = New-Object System.Drawing.Point(10, 80)
    $Display.Size = New-Object System.Drawing.Size(415, 300)
    $Display.BackColor = $WinWhite
    $Display.Font = $ConsoleFont
    $Display.ReadOnly = $true
    $Display.BorderStyle = "Fixed3D"

    $InputBox = New-Object Windows.Forms.TextBox
    $InputBox.Location = New-Object System.Drawing.Point(10, 395)
    $InputBox.Size = New-Object System.Drawing.Size(300, 25)
    $InputBox.Font = $ConsoleFont

    $SendBtn = New-Object Windows.Forms.Button
    $SendBtn.Text = "& Message"
    $SendBtn.Location = New-Object System.Drawing.Point(320, 393)
    $SendBtn.Size = New-Object System.Drawing.Size(105, 25)
    $SendBtn.FlatStyle = "Standard"
    $SendBtn.Font = $ClassicFont

    $FileBtn = New-Object Windows.Forms.Button
    $FileBtn.Text = "&Upload File"
    $FileBtn.Location = New-Object System.Drawing.Point(320, 425)
    $FileBtn.Size = New-Object System.Drawing.Size(105, 25)
    $FileBtn.Font = $ClassicFont

    $ExitBtn = New-Object Windows.Forms.Button
    $ExitBtn.Text = "Cancel"
    $ExitBtn.Location = New-Object System.Drawing.Point(320, 470)
    $ExitBtn.Size = New-Object System.Drawing.Size(105, 25)
    $ExitBtn.Font = $ClassicFont
    $ExitBtn.Add_Click({ $Form.Close() })

    $SendMsg = {
        if ($InputBox.Text.Trim() -ne "") {
            $Line = "[$(([DateTime]::Now).ToString('HH:mm:ss'))] > $($InputBox.Text)"
            Add-Content $File $Line
            $InputBox.Clear()
        }
    }

    $Timer = New-Object Windows.Forms.Timer
    $Timer.Interval = 1000
    $Timer.Add_Tick({
        if (Test-Path $File) {
            $txt = Get-Content $File -Raw
            if ($Display.Text -ne $txt) {
                $Display.Text = $txt
                $Display.SelectionStart = $Display.Text.Length
                $Display.ScrollToCaret()
            }
        }
    })

    $SendBtn.Add_Click($SendMsg)
    $FileBtn.Add_Click({
        $od = New-Object Windows.Forms.OpenFileDialog
        if ($od.ShowDialog() -eq "OK") {
            Copy-Item $od.FileName $Path
            "** FILE ATTACHED: $($od.SafeFileName) **" | Add-Content $File
        }
    })
    $InputBox.Add_KeyDown({ if ($_.KeyCode -eq "Enter") { & $SendMsg } })

    $Form.Controls.AddRange(@($Group, $Display, $InputBox, $SendBtn, $FileBtn, $ExitBtn))
    $Timer.Start()
    $Form.ShowDialog()

} catch {
    [System.Windows.Forms.MessageBox]::Show("Driver Critical Error: $($_.Exception.Message)", "System Error", 0, 16)
}
