# Fortsätt köra trots rapporterade fel:
set BreakOnAssertion 3

# Definiera design (både entity och filer):
set design "CountOnes"

# Kompilera koden:
vlib work
vcom -2002 ${design}.vhd
vcom -2002 ${design}_tb.vhd

# Ladda in koden i simulatorn
vsim -voptargs=+acc ${design}_tb

# Lägg till alla signaler i wave-fönstret:
add wave -divider {Top} /*
add wave -divider {DUT} -r /dut/*

# Stäng av eventuella varningar "Metavalue detected":
set NumericStdNoWarnings 1

# Kör tills det inte finns något kvar att simulera:
run -a

# Zooma wave-fönstret så att allt syns:
wave zoom full

# Lägg till kommandot "igen":
# alias igen "do rerun.do"
# add_cmdhelp igen {Kör "do rerun.do", vilket kompilerar om och startar om simuleringen.} {}

# echo "Jag har lagt till kommandot \"igen\" för att kompilera och köra om din kod."
