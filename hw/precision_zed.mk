# lab0 version for use with ise14.7i
# For precision:
$(WD)/lab0_zed.scr: $(VERILOGFILES)
	rm -f $(WD)/lab0_zed.scr;
	echo set_results_dir $(WD) > $(WD)/lab0_zed.scr
	echo -n 'add_input_file {' >> $(WD)/lab0_zed.scr
	if test -f /usr/bin/cygpath;then PATHCONV="cygpath -m";else PATHCONV=echo;fi;\
		for i in $(VERILOGFILES); do echo -n " \"`$$PATHCONV "$$PWD/$$i"`\"" >> $(WD)/lab0_zed.scr; done
	echo '}' >> $(WD)/lab0_zed.scr
	echo 'setup_design -design lab0_zed' >> $(WD)/lab0_zed.scr
	echo 'setup_design -frequency 100' >> $(WD)/lab0_zed.scr
	echo 'setup_design -manufacturer Xilinx -family ZYNQ -part 7Z020CLG484 -speed -1 -vivado=false ' >> $(WD)/lab0_zed.scr
	echo 'compile' >> $(WD)/lab0_zed.scr
	echo 'synthesize' >> $(WD)/lab0_zed.scr

$(WD)/lab0_zed.edf: $(WD)/lab0_zed.scr
	$(NICE) $(PRECISION) -shell -file $(WD)/lab0_zed.scr

$(WD)/lab0_zed.ngd: $(WD)/lab0_zed.edf lab0_zed.ucf
	rm -rf $(WD)/_ngo
	mkdir $(WD)/_ngo
	cp *.edn $(WD)
	cd $(WD); $(XILINX_INIT_ZED) ngdbuild -dd _ngo -nt timestamp -p $(PART_ZED) -uc $(PWD)/lab0_zed.ucf lab0_zed.edf  lab0_zed.ngd
