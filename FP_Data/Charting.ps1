<#
 .Synopsis
    Generate a chart (and optionally save to a file) for a given data set

 .Description
  Takes a source currency and amount and does the most recent FX rate conversion returning the amount in USD

 .Parameter DataSets
  The data set(s) to chart. If only one "series" is needed on the chart then just provide an array of pscustomobject with x, y and optionally z values (see examples)
  For multiple "series" give an array of arrays of pscustomobject with series (name), x, y and optionally z values

 .Parameter ChartTitle
  The title of the chart to generate

 .Parameter XAxisTitle
  The X Axis Title (shown only for some chart types so can be left default)

 .Parameter YAxisTitle
  The Y Axis Title (shown only for some chart types so can be left default)

 .Parameter Width
  The Initial Width of the chart (and form it's rendered in)

 .Parameter Height
  The Initial Height of the chart (and form it's rendered in)

 .Parameter BackgroundColor
  The Chart background color

 .Parameter ChartType
  The type of chart to render. Must be a member of the Enum: System.Windows.Forms.DataVisualization.Charting.SeriesChartType

 .Parameter OutPath
  A path to a file to save this chart. If specified the chart will be saved to that location and filename

 .Parameter ShowChart
  If the chart should be shown in a winform (you can specify OutPath only to just save a file of the chart)

 .Example
    # Chart a pie chart with each proccess and the number of instances for that process
    $DataSet = Get-Process | Group-Object {$_.ProcessName} |% {[PSCustomObject] @{X = $_.Name; Y = $_.Count}}
    New-Chart -DataSets $DataSet -ChartTitle "Processes By Instance Count" -ChartType "Pie" -ShowChart

    # Create a bubble chart with an x, y placement and a z size. Data is grouped into series by New-DataForTSVChart
    $DataSet = New-DataForTSVChart -TsvPath "C:\Users\fopitz\Downloads\HourlyProcessedMessageDelayByDeliveryCount_2019_04_08_2019_04_09.tsv"
    New-Chart -DataSets $DataSet -ChartTitle "Hourly Processed Message Delay By DeliveryCount" -XAxisTitle "Time" -YAxisTitle "Delay (Hours)" -ChartType "Bubble" -ShowChart
#>
function New-Chart(){
   param(
      $DataSets,
      [string] $ChartTitle,
      [string] $XAxisTitle = "X",
      [string] $YAxisTitle = "Y",
      [int] $Width = 1200,
      [int] $Height = 600,
      [System.Drawing.Color] $BackgroundColor = [System.Drawing.Color]::White,
      [ValidateSet("Area", "Pie", "Bar", "Scatter", "Line", "Column", "Bubble")]
      [string] $ChartType,
      [string] $OutPath = "",
      [parameter()] [switch] $ShowChart      
   )

   [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
   #$scriptpath = Split-Path -parent $MyInvocation.MyCommand.Definition

   # Construct the chart
   $chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
   $chart.Width = $Width
   $chart.Height = $Height
   $chart.BackColor = $BackgroundColor
 
   # Add the chart title 
   [void]$chart.Titles.Add($ChartTitle)
   $chart.Titles[0].Font = "Arial,13pt"
   $chart.Titles[0].Alignment = "topLeft"
 
   # Construct the chart area 
   $chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
   $chartarea.Name = "ChartArea1"
   $chartarea.AxisY.Title = $YAxisTitle
   $chartarea.AxisX.Title = $XAxisTitle

   # TODO: Adjust interval to fit data
   $chartarea.AxisY.Interval = 1
   $chartarea.AxisX.Interval = 1
   $chart.ChartAreas.Add($chartarea)
 
   # Consturct the legend 
   $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
   $legend.name = "Legend1"
   $chart.Legends.Add($legend)

   #If the input data set has only one series we fake that it's an array of one so the below code can be generic
   if ($null -ne (Get-Member -Name "X" -InputObject $DataSets[0]))
   {
        Write-Host "only one series found"
        $DataSets = @(, $DataSets)
   }

    Write-Host "Dataset Count", $DataSets.Count   

   for ($i = 0; $i -lt $DataSets.Count; $i += 1)
   {
        Write-Host "Processing $i"
        if ($null -ne $DataSets[$i][0].Series)
        {
            [void]$chart.Series.Add($DataSets[$i][0].Series)
        }
        else 
        {
            [void]$chart.Series.Add("Series")
        }
        $chart.Series[$i].ChartType = $ChartType
        $chart.Series[$i].BorderWidth  = 3
        $chart.Series[$i].IsVisibleInLegend = $true
        $chart.Series[$i].chartarea = "ChartArea1"
        $chart.Series[$i].Legend = "Legend1"

        if ($ChartType -eq "Pie")
        {
            $chart.Series[$i]["PieLabelStyle"] = "Outside"
            $chart.ChartAreas[0].Area3DStyle.Enable3D = $true;
            $chart.ChartAreas[0].Area3DStyle.Inclination = 10;
        }

        $DataSets[$i] | ForEach-Object { 
                if ($null -ne $_.Z)
                {
                    Write-Host "Adding ", $_.X, $_.Y, $_.Z 
                    $chart.Series[$i].Points.addxy( $_.X , $_.Y, $_.Z ) 
                }
                else
                {
                    $chart.Series[$i].Points.addxy( $_.X , $_.Y ) 
                }
            }
    
    }

   # Save the chart to a file
   if ($OutPath -ne "")
   {
      if ([System.IO.Path]::IsPathRooted($OutPath))
      {
         $chart.SaveImage("$OutPath",[System.IO.Path]::GetExtension($OutPath))
      }
      else 
      {
        $chart.SaveImage("$scriptpath\$OutPath",[System.IO.Path]::GetExtension($OutPath))
      }
   }

   if ($ShowChart)
   {
      $AnchorAll = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right -bor
      [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
      $Form = New-Object Windows.Forms.Form
      $Form.Width = $Width
    
      # Make room for the x axis title
      $Form.Height = $Height + 50
      $Form.controls.add($chart)
      $chart.Anchor = $AnchorAll
      
      $Form.Add_Shown({$Form.Activate()})
      [void]$Form.ShowDialog()
   }
}

<#
 .Synopsis
  Takes a TSV with columns "Series", "X", "Y", and optionally "Z" and converts it to an object that's understandable by New-Chart

 .Parameter TsvPath
  The path to the TSV File

 .Example
    $DataSet = New-DataForTSV3DChart -TsvPath "C:\Users\fopitz\Downloads\HourlyProcessedMessageDelayByDeliveryCount_2019_04_08_2019_04_09.tsv"
    New-Chart -DataSets $DataSet -ChartTitle "Hourly Processed Message Delay By DeliveryCount" -XAxisTitle "Time" -YAxisTitle "Delay (Hours)" -ChartType "Bubble" -ShowChart
#>
function New-DataForTSVChart()
{
    param(
        [string] $TsvPath
    )

    $inputs = Import-Csv -Path $TsvPath -Delimiter `t
    $inputHash = $inputs | Group-Object {$_.series} -AsHashTable -AsString
    $data = @()
    $inputHash.Keys |Foreach-Object {
        Write-Host "Processing points for Series `"$_`""
        $series = @()
        $inputHash[$_] |Foreach-Object {
            if ($null -ne (Get-Member -Name "Z" -InputObject $_))
            {
                $series += [PSCustomObject] @{Series = $_.series; X = $_.x; Y = $_.y ;Z = $_.z}
            }
            else 
            {
                $series += [PSCustomObject] @{Series = $_.series; X = $_.x; Y = $_.y}
            }
        }

        $data += , $series
        
        $series = @()
    }
    
    return $data
}