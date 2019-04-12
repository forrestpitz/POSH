# Helper functions. No Get-Help documentation becuase we can use the helper below
function ConvertTo-Base64String( [string] $s)   { [Convert]::ToBase64String( [System.Text.Encoding]::Utf8.GetBytes($s)) }
function ConvertFrom-Base64String( [string] $s) { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($s))}

<#
.SYNOPSIS
    Convert a string from/to Base64 string
.Parameter input
  The input string
.Parameter From
  If the conversion is from or to a base 64 string
.EXAMPLE
    'foo bar' | Convert-Base64String | % { Write-Host $_; $_ } | Convert-Base64String -From
    # Expected Response: Encode string 'foo bar' to Base64 form, dispaly it, and decode it.
#>
function Convert-Base64String () 
{
    [alias("b64")]
    param(
        [Parameter(ValueFromPipeline=$true)] [string] $input,
         [switch]$From
    )

    if ($From) 
    {
        ConvertFrom-Base64String $input 
    } 
    else 
    {
        ConvertTo-Base64String $input
    }
}