echo $args[0] $args[1] $args[2]
$gif=$args[0]
$filedir=$args[1]
$filename=$args[2]
x16emu -echo -sdcard "C:\SDCARD\X16.vhd" -gif $gif -prg $filedir\$filename -debug
