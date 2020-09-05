yosysscript=script.yosys
default_yosys_script ?= ../default_yosys
yosys_synth_result ?= synth.v
$(yosys_synth_result): $(yosysscript) $(files)
	yosys -s $(yosysscript)

$(yosysscript): Makefile $(default_yosys_script)
	echo > $(yosysscript)
	echo $(foreach f, $(files),"read_verilog $f;") >> $(yosysscript)
	echo hierarchy -check -top $(top) >> $(yosysscript)
	cat $(default_yosys_script) >> $(yosysscript)
clean.yosys:
	rm -rf script.yosys $(yosys_synth_result)
clean: clean.yosys