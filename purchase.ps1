# purchase.ps1 - Clean working version
$PROXY = "https://poof-oqvo.onrender.com"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "YEAPS PURCHASE TOOL" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# === USER INPUT ===
$OCULUS_ID = Read-Host "`nEnter Oculus ID"
$MOBILE_CODE = Read-Host "Enter mobile code"

# === ROTATION SELECTION ===
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "SELECT ROTATION KEY" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  1. techWeb"
Write-Host "  2. cosmeticsStore"
Write-Host "  3. recordStore"
Write-Host "  4. tapeStore"
Write-Host "  5. rareStore"
Write-Host "  6. buildingStore"
Write-Host "  7. toyStore"
Write-Host "  8. petItemStore"
Write-Host "  9. petStore"
Write-Host "  10. petCosmeticsStore"
Write-Host "  11. featuredGameMode"

$rotChoice = Read-Host "`nSelect rotation (1-11, default: 1)"

if ($rotChoice -eq "1") { $buyingFrom = "techWeb" }
elseif ($rotChoice -eq "2") { $buyingFrom = "cosmeticsStore" }
elseif ($rotChoice -eq "3") { $buyingFrom = "recordStore" }
elseif ($rotChoice -eq "4") { $buyingFrom = "tapeStore" }
elseif ($rotChoice -eq "5") { $buyingFrom = "rareStore" }
elseif ($rotChoice -eq "6") { $buyingFrom = "buildingStore" }
elseif ($rotChoice -eq "7") { $buyingFrom = "toyStore" }
elseif ($rotChoice -eq "8") { $buyingFrom = "petItemStore" }
elseif ($rotChoice -eq "9") { $buyingFrom = "petStore" }
elseif ($rotChoice -eq "10") { $buyingFrom = "petCosmeticsStore" }
elseif ($rotChoice -eq "11") { $buyingFrom = "featuredGameMode" }
else { $buyingFrom = "techWeb" }

Write-Host "Selected: $buyingFrom" -ForegroundColor Green

# === LOGIN ===
Write-Host "`nLogging in..." -ForegroundColor Yellow

$loginBody = @{
    oculusID = $OCULUS_ID
    mobileCode = $MOBILE_CODE
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$PROXY/buy" -Method Post -ContentType "application/json" -Body $loginBody -TimeoutSec 30
    $sessionID = $loginResponse.sessionID
    Write-Host "Logged in! Session: $sessionID" -ForegroundColor Green
} catch {
    Write-Host "Login failed: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# === BUY LOOP ===
do {
    Write-Host "`n=========================================" -ForegroundColor Cyan
    Write-Host "BUY ITEM" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan

    $item = Read-Host "`nEnter Item ID"
    $price = Read-Host "Enter Expected Price (default: 0)"
    if ($price -eq "") { $price = 0 }

    # === WAIT FOR PURCHASES ===
    Write-Host "`n=========================================" -ForegroundColor Yellow
    Write-Host "IMPORTANT!" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "1. Go to Yeeps on VR"
    Write-Host "2. Enable Purchases in settings"
    Write-Host "3. Press Enter to continue"
    Write-Host "=========================================" -ForegroundColor Yellow
    Read-Host "`nPress Enter when purchases are enabled"

    # === BUY ===
    Write-Host "Sending purchase request..." -ForegroundColor Yellow

    $itemBody = @{
        sessionID = $sessionID
        item = $item
        expectedPrice = [int]$price
        buyingFrom = $buyingFrom
    } | ConvertTo-Json

    try {
        $result = Invoke-RestMethod -Uri "$PROXY/buy/item" -Method Post -ContentType "application/json" -Body $itemBody -TimeoutSec 30
        Write-Host "Purchase successful!" -ForegroundColor Green
        $result | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "Purchase failed: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $errorBody = $reader.ReadToEnd()
            Write-Host "Error: $errorBody" -ForegroundColor Red
        }
    }

    $continue = Read-Host "`nBuy another item? (y/n)"
} while ($continue -eq "y")

Write-Host "`nDone!" -ForegroundColor Cyan
Read-Host "Press Enter to close"