onerror {quit -f}
vlib work
vlog -work work MessageScheduler.vo
vlog -work work MessageScheduler.vt
vsim -novopt -c -t 1ps -L cycloneii_ver -L altera_ver -L altera_mf_ver -L 220model_ver -L sgate work.MessageScheduler_vlg_vec_tst
vcd file -direction MessageScheduler.msim.vcd
vcd add -internal MessageScheduler_vlg_vec_tst/*
vcd add -internal MessageScheduler_vlg_vec_tst/i1/*
add wave /*
run -all
