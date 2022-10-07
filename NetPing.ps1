$netadr = $args[0]
$delay = 2 # ping timeout
$lang = (get-Culture).TwoLetterISOLanguageName

if ($lang -ne "ru") {    # language message
    $lang = "en"
} 
$msgs=@{}  # messages
$msgs["ru"]=(" Ошибка : необходим параметр в формате x.x.x.x/m (где x от 0 по 255, m от 24 по 30)",
    " Ошибка : в данной версии скрипта маска может быть от 24 и по 30 включительно",
    " Ошибка : неверный начальный адрес сети ",
    ", для маски ",
    "`n возможны только",
    "Проверка доступности ",
    "       Адрес        Время",
    " мс",
    "----- Получен ответ от ",
    "Ответов на ping не получено")
$msgs["en"] = (" Error : required parameter in x.x.x.x/m format (x from 0 to 255, m from 24 to 30)",
    " Error: in this version of the script, the mask can be from 24 to 30 inclusive",
    " Error: Invalid network start address ",
    ", for mask ",
    "`n only possible:",
    "Availability check",
    "      Address       Time",
    " ms",
    "Received response from ",
    "No ping replies received")
    

if (-not $netadr) {   
    $msgs[$lang][0]   # no parameter
    exit
}
$nmsk = $netadr.IndexOf("/")
if ($nmsk -lt 0) {    # parameter format check
    $msgs[$lang][0]
    exit
}
$msk = $netadr.SubString($nmsk + 1)
if (-not ($msk -match "^\d+$")) {
    $msgs[$lang][0]   # digit check mask
    exit
}
$msk = [int]$msk
if ($msk -lt 24 -or $msk -gt 30){
    $msgs[$lang][1]   # mask range check
    exit
}
$net = $netadr.SubString(0,$nmsk)
$ips = $net -split "\."
if ($ips.length -ne 4) {
    $msgs[$lang][0]   # check network
    exit
}
foreach($d in $ips){
    if (-not ($d -match "^\d+$")){
        $msgs[$lang][0]  # digit check network
        exit
    } else {
        $dd = [int]$d
        if ($dd -lt 0 -or $dd -gt 255) {
            $msgs[$lang][0]      # network range check
            exit    
        }
    }
}
$startnet = [int]$ips[3]
$found = $False
$vld = ""
for ($i = 0; $i -lt 256; $i += 256/[math]::Pow(2,$msk - 24)){
    if ($startnet -eq $i) {
       $found = $True
       break 
    }
    $vld += (" " + $i.ToString())
}
if (-not $found){  # network and mask compatibility check
     $msgs[$lang][2]+$startnet+$msgs[$lang][3]+$msk+$msgs[$lang][4]+$vld
     exit 
}
$start = $startnet + 1
$end =  $startnet + [math]::Pow(2, 32 - $msk) - 1
$net = $net.SubString(0,$net.LastIndexOf(".") + 1)
$count = 0
for ($i = $Start; $i -lt $end; $i++) {
    $hst = $net+$i.ToString()
    Write-Progress -Activity $msgs[$lang][5] -Status $hst -PercentComplete (($i-$StartNet-1)*100/($end+1-$startNet))
    $tst = Test-Connection $hst -Count 1 -ErrorAction SilentlyContinue -Delay $delay -BufferSize 32
    if($tst) {
        if ($count -eq 0) {
        $msgs[$lang][6]
        "============================"
        }
        $tst.Address.PadLeft(15) + $tst.ResponseTime.ToString().PadLeft(8) + $msgs[$lang][7]
        $count++
    }
}
if($count -ne 0) {
    $msgs[$lang][8]+$count
} else {
    $msgs[$lang][9] 
}
