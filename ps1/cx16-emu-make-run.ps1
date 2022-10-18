echo $args[0] $args[1] $args[2]
$workspacedir=$args[0]
$dir=$args[1]
$file=$args[2]

diskpart /s cmd/attach.dsk
Remove-Item -Path X:\* -Recurse

echo "Copying graphics"
copy-item  -Verbose -Recurse -Force -Path "$workspacedir/$dir/../graphics/target/*.BIN" "X:/"
echo "Copying Program"
copy-item -Verbose -Path "$workspacedir/$dir/../target/*.PRG" "X:/"
copy-item -Verbose -Path "$workspacedir/$dir/target/*.BIN" "X:/" 
copy-item -Verbose -Path "$workspacedir/$dir/../target/*.BIN" "X:/"

diskpart /s cmd/detach.dsk

cd $workspacedir/$dir/../target

Get-ChildItem | Rename-Item -NewName { $_.Basename.ToUpper() + $_.Extension.ToUpper() }

#x16emu -echo -sdcard "C:\SDCARD\CX16.vhd" -prg $workspacedir\$dir\..\target\$file.prg -debug -keymap fr-be
x16emu -sdcard "C:\SDCARD\CX16.vhd" -keymap fr-be -prg "$file.prg"
