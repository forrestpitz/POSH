<#
 .Synopsis
  Converts an amount from a source currency to USD.

 .Description
  Takes a source currency and amount and does the most recent FX rate conversion returning the amount in USD

 .Parameter SourceCurrency
  The currency to convert from

 .Parameter SourceAmount
  The amount to convert

 .Example
   # Get the amount from Pesos to USD
   ConvertTo-USD -SourceCurrency "MXN" -SourceAmount 50
   # Expected response as of 03/2018 = 954.537866
#>
function ConvertTo-USD()
{
   Param
   (
       [Parameter(Mandatory=$True)]
       [string] $SourceCurrency,
       [Parameter(Mandatory=$True)]
       [double] $SourceAmount
   )

    [xml]$doc = (New-Object System.Net.WebClient).DownloadString("http://www.floatrates.com/daily/usd.xml")
    $items = $doc.SelectNodes("//item")

    $fxRates = @()

    foreach ($item in $items) {
        $fxRate = @{}
        $fxRate.SourceCurrency = $item.targetCurrency
        $fxRate.ExchangeRate = $item.exchangeRate

        $fxRates += $fxRate
    }

    #add USD since it doesn't come for free
    $fxRate = @{}
    $fxRate.SourceCurrency = "USD"
    $fxRate.exchangeRate = 1
    $fxRates += $fxRate

    $fxRates | Where-Object {$_.SourceCurrency -eq $SourceCurrency} | ForEach-Object { $_.exchangeRate -as [double]} | ForEach-Object {$_ * $SourceAmount}
}