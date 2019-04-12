<#
 .Synopsis
  Split a CSV file into multiple files

 .Description
  Splits a very large CSV file into a number of smaller CSV files to allow for batch processing of a large data set

 .Parameter SourceCSV
  A path to the input CSV file

 .Parameter BatchSize
  How many rows to put into each destination CSV file

 .Example
   # Get the amount from Pesos to USD
   Split-CSV -SourceCSV input.csv -BatchSize 100
   # Expected response is a number of csv files with 100 rows from the input.csv
#>
function Split-CSV()
{
    Param
    (
        [Parameter(Mandatory=$True)]
        [string] $SourceCSV,
        [double] $BatchSize = 10000
    )

    $StartRow = 0;
    $Counter = 1;
    $DestinationFileName =  (Get-Item $SourceCSV).Basename

    while ($StartRow -lt $SourceCSV.Length)
    {
        Import-CSV $SourceCSV | select-object -skip $StartRow -first $BatchSize | Export-CSV "$DestinationFileName" + "_" + $Counter + ".csv" -NoClobber;
        $StartRow += $BatchSize;
        $Counter++;
    }
}