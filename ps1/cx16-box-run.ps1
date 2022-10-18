echo $args[0] $args[1] $args[2]
$workspacedir=$args[0]
$dir=$args[1]
$file=$args[2]

box16 -echo -sym "$workspacedir/$dir/$file.vs" -vsync none -keymap fr-be -prg $workspacedir/$dir/../target/$file.prg
