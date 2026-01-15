$tcpClient = New-Object System.Net.Sockets.TcpClient("api.anthropic.com", 443)
$chain = $null
$cert = $null
$callback = [System.Net.Security.RemoteCertificateValidationCallback] {
    param($sender, $certificate, $chainObj, $errors)
    $script:chain = $chainObj
    $script:cert = $certificate
    return $true
}
$sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, $callback)
$sslStream.AuthenticateAsClient("api.anthropic.com")

Write-Host "=== Certificate Chain to api.anthropic.com ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "[0] Server Certificate:" -ForegroundColor Yellow
Write-Host "    Subject: $($script:cert.Subject)"
Write-Host "    Issuer: $($script:cert.Issuer)"
Write-Host ""

$i = 1
foreach ($elem in $script:chain.ChainElements) {
    if ($elem.Certificate.Subject -ne $script:cert.Subject) {
        Write-Host "[$i] Chain Element:" -ForegroundColor Yellow
        Write-Host "    Subject: $($elem.Certificate.Subject)"
        Write-Host "    Issuer: $($elem.Certificate.Issuer)"
        Write-Host ""
        $i++
    }
}

# Check for suspicious issuers
$suspiciousIssuers = @("Zscaler", "Palo Alto", "Blue Coat", "Fortinet", "Symantec", "McAfee", "Websense", "Barracuda", "Sophos", "Forcepoint", "Netskope", "Cisco Umbrella")
$foundSuspicious = $false
foreach ($elem in $script:chain.ChainElements) {
    foreach ($suspicious in $suspiciousIssuers) {
        if ($elem.Certificate.Issuer -match $suspicious -or $elem.Certificate.Subject -match $suspicious) {
            Write-Host "WARNING: Potential MITM detected - $suspicious in certificate chain!" -ForegroundColor Red
            $foundSuspicious = $true
        }
    }
}

if (-not $foundSuspicious) {
    Write-Host "Certificate chain appears legitimate (no known SSL inspection products detected)" -ForegroundColor Green
}

$sslStream.Close()
$tcpClient.Close()

