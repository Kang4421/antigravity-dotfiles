<#
.SYNOPSIS
    파일 및 폴더를 영구 삭제하지 않고 Windows 휴지통으로 안전하게 이동합니다.
#>
param(
    [Parameter(Position = 0, Mandatory = $true, ValueFromRemainingArguments = $true)]
    [string[]]$Path
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName Microsoft.VisualBasic

foreach ($p in $Path) {
    if (-not $p) { continue }
    # 따옴표 제거 (cmd에서 전달될 때 남아있는 따옴표 처리)
    $cleanPath = $p.Trim('"').Trim("'")
    
    $items = @()
    if (Test-Path -Path $cleanPath) {
        $items = @(Get-Item -Path $cleanPath -Force -ErrorAction SilentlyContinue)
    }
    elseif (Test-Path -LiteralPath $cleanPath) {
        $items = @(Get-Item -LiteralPath $cleanPath -Force -ErrorAction SilentlyContinue)
    }
    else {
        Write-Warning "경로를 찾을 수 없습니다: $cleanPath"
        continue
    }

    foreach ($item in $items) {
        if (-not $item) { continue }
        $fullPath = $item.FullName
        try {
            if ($item.PSIsContainer) {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
                    $fullPath,
                    [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                    [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                )
                Write-Host "[휴지통 이동 완료] 폴더: $fullPath"
            }
            else {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                    $fullPath,
                    [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                    [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
                )
                Write-Host "[휴지통 이동 완료] 파일: $fullPath"
            }
        }
        catch {
            Write-Error "휴지통 이동 실패 ($fullPath): $_"
        }
    }
}
