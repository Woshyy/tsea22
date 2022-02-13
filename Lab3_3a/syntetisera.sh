#!/bin/bash
# Script för att syntetisera VHDL till Xilinx XC9572
# Oscar Gustafsson, oscar.gustafsson@liu.se
# Petter Källström, petter.kallstrom@liu.se

# Ange namnet för toppmodulen här, dvs den entity som är huvudkonstruktionen
toppmodul=comb_lock_logic

# Ange filnamn, t.ex. filer=(minkrets.vhdl counter.vhd enpulsare.vhd)
# filer=("$toppmodul".vhd)

# Inget mer behöver ändras nedan

# CPLD/FPGA som används
family=xc9500
device=xc9572
package=PC44
speedgrade=7

# Skapa projektfil med alla filnamn
projektfil="${toppmodul}.prj"

# Ta bort gammal version av filen om den finns
if test -f "$projektfil"; then
   rm -f "$projektfil"
fi

if [ -z ${filer+x} ]; then
    # Bara en fil
    if [ -e "$toppmodul".vhd ]; then
        echo vhdl work "$toppmodul".vhd >> "$projektfil"
    elif [ -e "$toppmodul".vhdl ]; then
        echo vhdl work "$toppmodul".vhdl >> "$projektfil"
    else
        echo "Error: Could not find $toppmodul.vhd or .vhdl" >> /dev/stderr
        exit 1
    fi
else
    # Flera filer
    for fil in "${filer[@]}"
    do
        echo vhdl work "$fil" >> "$projektfil"
    done
fi

# Skapa instruktioner till verktyget
xstfil="${toppmodul}.xst"
utfil="${toppmodul}.ngc"

# Ta bort gammal version av filen om den finns
if test -f "$xstfil"; then
   rm -f "$xstfil"
fi

echo run >> "$xstfil"
echo -ifn "$projektfil" >> "$xstfil"
echo -top "$toppmodul" >> "$xstfil"
echo -p "$family" >> "$xstfil"
echo -ofn "$utfil" >> "$xstfil"
echo -opt_mode speed >> "$xstfil"
echo -opt_level 1 >> "$xstfil"

# Kör syntesen
echo "## Synthesize $toppmodul: log_1_xst.txt"
#echo "## Synthesize: xst -ifn \"$xstfil\""
if ! (xst -ifn "$xstfil" > log_1_xst.txt ) then
  cat log_1_xst.txt | egrep "ERROR|WARNING"
  exit 1
else
  cat log_1_xst.txt | egrep "ERROR|WARNING"
fi

echo "## Translate: log_2_ngd.txt"
#echo "## Translate: ngdbuild -dd _ngo -i -p \"${device}-${package}-${speedgrade}\" \"${toppmodul}.ngc\" \"${toppmodul}.ngd\""
if ! (ngdbuild -dd _ngo -i -p "${device}-${package}-${speedgrade}" "${toppmodul}.ngc" "${toppmodul}.ngd"  > log_2_ngd.txt ) then
  cat log_2_ngd.txt | egrep "ERROR|WARNING"
  exit 1
fi

echo "## Fit: log_3_fit.txt"
#echo "## Fit: cpldfit -p \"${device}-${speedgrade}-${package}\" -ofmt vhdl -optimize speed -htmlrpt -loc on -slew fast -init low -inputs 36 -pterms 25 -power std -localfbk -pinfbk \"${toppmodul}.ngd\""
if ! (cpldfit -p "${device}-${speedgrade}-${package}" -ofmt vhdl -optimize speed -htmlrpt -loc on -slew fast -init low -inputs 36 -pterms 25 -power std -localfbk -pinfbk "${toppmodul}.ngd" > log_3_fit.txt ) then
  cat log_3_fit.txt | egrep "ERROR|WARNING"
  exit 1
else
	cat log_3_fit.txt | tail -n 2
fi

echo "## Generate .jed: log_4_jed.txt"
#echo "## Generate .jed: hprep6 -s IEEE1149 -n \"${toppmodul}\" -i \"${toppmodul}\""
if ! (hprep6 -s IEEE1149 -n "${toppmodul}" -i "${toppmodul}" > log_4_jed.txt ) then
  cat log_4_jed.txt | egrep "ERROR|WARNING"
  exit 1
else
  echo "Generated ${toppmodul}.jed sucessfully"
fi
