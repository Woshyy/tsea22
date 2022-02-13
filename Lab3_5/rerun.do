# kompilera om koden:
vcom -2002 ${design}.vhd
vcom -2002 ${design}_tb.vhd

# starta om simuleringen (men håll den öppen):
restart -f

# Kör så länge det finns aktiviteter att göra (d.v.s. så länge klockan går):
run -a

# Zooma wave-fönster till att visa allt:
wave zoom full

