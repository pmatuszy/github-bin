

rozszerzenia="$1"
testujemy='--nono'

{
rename $testujemy -v 's/!/./g' $rozszerzenia
rename $testujemy -v 's|Ę|E|g' $rozszerzenia
rename $testujemy -v 's|Ć|C|g' $rozszerzenia
rename $testujemy -v 's|Ó|O|g' $rozszerzenia
rename $testujemy -v 's|Ł|L|g' $rozszerzenia
rename $testujemy -v 's|Ą|A|g' $rozszerzenia
rename $testujemy -v 's|Ć|C|g' $rozszerzenia
rename $testujemy -v 's|Ś|S|g' $rozszerzenia
rename $testujemy -v 's|Ż|Z|g' $rozszerzenia
rename $testujemy -v 's|Ź|Z|g' $rozszerzenia
rename $testujemy -v 's|Ń|N|g' $rozszerzenia
}

{
rename $testujemy -v 's|ę|e|g'  $rozszerzenia
rename $testujemy -v 's|ć|c|g'  $rozszerzenia
rename $testujemy -v 's|ó|o|g'  $rozszerzenia
rename $testujemy -v 's|ł|l|g'  $rozszerzenia
rename $testujemy -v 's|ą|a|g'  $rozszerzenia
rename $testujemy -v 's|ć|c|g'  $rozszerzenia
rename $testujemy -v 's|ś|s|g'  $rozszerzenia
rename $testujemy -v 's|ż|z|g'  $rozszerzenia
rename $testujemy -v 's|ź|z|g'  $rozszerzenia
rename $testujemy -v 's|ń|n|g'  $rozszerzenia
}

{
rename $testujemy -v 's|ż|z|g'    $rozszerzenia
rename $testujemy -v 's|ź|z|g'    $rozszerzenia
rename $testujemy -v 's|ń|n|g'    $rozszerzenia
rename $testujemy -v 's|\[|_|g'   $rozszerzenia
rename $testujemy -v 's|\]|_|g'   $rozszerzenia
rename $testujemy -v 's|\(|_|g'   $rozszerzenia
rename $testujemy -v 's|\)|_|g'   $rozszerzenia
rename $testujemy -v 's|__|_|g'   $rozszerzenia
rename $testujemy -v 's|_\.|\.|g' $rozszerzenia
rename $testujemy -v 's|_$|\.|g'  $rozszerzenia
}

{
rename $testujemy -v 's|•|-|g'     $rozszerzenia
rename $testujemy -v "s|\'|_|g"    $rozszerzenia
rename $testujemy -v "s|&|_and_|g" $rozszerzenia
rename $testujemy -v "s| |_|g"     $rozszerzenia
rename $testujemy -v "s|,|_|g"     $rozszerzenia
rename $testujemy -v "s|{|_|g"     $rozszerzenia
rename $testujemy -v "s|}|_|g"     $rozszerzenia
}

{
rename $testujemy -v "s|\'|_|g"    $rozszerzenia
rename $testujemy -v "s|&|_and_|g" $rozszerzenia
rename $testujemy -v "s| |_|g"     $rozszerzenia
rename $testujemy -v "s|,|_|g"     $rozszerzenia
rename $testujemy -v "s|{|_|g"     $rozszerzenia
rename $testujemy -v "s|}|_|g"     $rozszerzenia
}

{
rename $testujemy -v 's|\[|_|g'   $rozszerzenia
rename $testujemy -v 's|\]|_|g'   $rozszerzenia
rename $testujemy -v 's|\(|_|g'   $rozszerzenia
rename $testujemy -v 's|\)|_|g'   $rozszerzenia
rename $testujemy -v 's|__|_|g'   $rozszerzenia
rename $testujemy -v 's|_\.|\.|g' $rozszerzenia
rename $testujemy -v 's|_$|\.|g'  $rozszerzenia
rename $testujemy -v 's|\.$||g'  $rozszerzenia
}

