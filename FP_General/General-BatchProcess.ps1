<#
 .Synopsis
  Run a function in batch.

 .Description
  Takes an input file or clipboard contents and runs the FunctionToCall in batch for each delimited row of that input 

 .Parameter FunctionToCall
  The function to execute

 .Parameter Filepath
  The path to a file with the inputs to run against the FunctionToCall if FromClipboard is not set.
  The first line of the file specifies the types of each column

 .Parameter AdditionalParams
  Any additional parameters to pass to each call to the FunctionToCall

 .Parameter BatchSize
  How many lines to run against the FunctionToCall in batch

 .Parameter Delimiter
  The delimiter used to split each line of input (file or clipboard)

 .Parameter FromClipboard
  A switch to get input from the keyboard

 .Example
   # Run Get-ChildItem (dir) for a set of directories in an input file looking only for ps1 files
   Invoke-BatchProcess -FunctionToCall "gci" -FilePath .\data\directorybatchinput.txt -AdditionalParams "-Include *.ps1"
   Invoke-BatchProcess -FunctionToCall "write-host" -FilePath .\data\lotsofnumbers.txt -AdditionalParams "-Color Red"
#>
function Invoke-BatchProcess
{
    Param
    (
       [Parameter(Mandatory=$True)]
       [string] $FunctionToCall,
       [string] $FilePath,
       [string] $AdditionalParams,
       [string] $BatchSize = 50,
       [string] $Delimetor = '`t',
       [switch] $FromClipboard
    )

    $Position = 1

    if ($FromClipboard)
    {
        $InputLines = Get-Clipboard
    }
    else
    {
        $InputLines = Get-Content $FilePath
    }

    $CommandsToProcess = @()
    $Types = @()
    $Results

    foreach ($Line in $InputLines)
    {
        # the input type format
        if ($Position -eq 1)
        {
            $Types = $Line -split $Delimetor
            $Position += 1
            continue
        }
        
        # Create the command to 
        $ParameterStrings = @()
        $Params = $Line -split $Delimetor
        for ($p = 0; $p -lt $Params.Count; $p += 1)
        {
            if($Types[$p] -eq "string")
            {
                $ParameterStrings += '"' + $Params[$p] + '"'
            } else 
            {
                $ParameterStrings += $Params[$p]
            }
        }

        $ParameterString = if($ParameterStrings.Length -eq 1){$ParameterStrings[0]} else {$ParameterStrings -join ' '}

        $command = $FunctionToCall + ' ' + $ParameterString + ' ' + $AdditionalParams
        $CommandsToProcess += $command

        if ($Position % $BatchSize -eq 0 ) #-or $Position -eq $InputLines.Count)
        {
            #$CommandsToProcess |% {Write-Output "$_"} >> .\testlog.txt
            # Execute the function in parallel
            $Results += $CommandsToProcess |% {Invoke-Expression $_}  # Split-Pipeline -Script {process{ Invoke-Expression $_ }} -Order

            # Clear the batch
            $CommandsToProcess.Clear()
        }

        $Position += 1
    }

    return $Results
}