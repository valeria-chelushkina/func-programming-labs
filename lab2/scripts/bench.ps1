param(
    [string]$Function = "heavy",
    [double]$A = 0,
    [double]$B = 1,
    [double]$Eps = 1e-10,
    [int[]]$Cores = @(1, 2, 4, 8),
    [int]$Repeats = 3
)

$ErrorActionPreference = "Stop"
Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    cabal build | Out-Null
    $exe = (& cabal list-bin lab2 2>$null | Select-Object -Last 1).Trim()

    function Measure-Run {
        param([string]$Mode, [int]$N)
        $times = @()
        for ($i = 0; $i -lt $Repeats; $i++) {
            $out = & $exe --mode $Mode --function $Function $A $B $Eps +RTS "-N$N" -RTS 2>&1
            $text = $out -join "`n"
            $match = [regex]::Match($text, 'time\s+=\s+([0-9.]+) s')
            if (-not $match.Success) {
                throw "Could not parse time (mode=$Mode, N=$N):`n$text"
            }
            $times += [double]$match.Groups[1].Value
        }
        return ($times | Measure-Object -Average).Average
    }

    Write-Host "function=$Function  interval=[$A, $B]  eps=$Eps  repeats=$Repeats"
    Write-Host ""
    "{0,6} {1,5} {2,12} {3,10}" -f "N", "mode", "time (s)", "speedup"

    $seqTime = Measure-Run "seq" 1
    "{0,6} {1,5} {2,12:N3} {3,10:N2}" -f 1, "seq", $seqTime, 1.0

    foreach ($n in $Cores) {
        $parTime = Measure-Run "par" $n
        "{0,6} {1,5} {2,12:N3} {3,10:N2}" -f $n, "par", $parTime, ($seqTime / $parTime)
    }
} finally {
    Pop-Location
}
