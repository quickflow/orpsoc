ifndef ZEBU_ROOT
    $(error ZEBU_ROOT is undefined, Make sure you have loaded in the zebu setup)
endif

ZCUIWORK=./zcui.work
CXX=g++ -Wall
INCL_PATH=-I$(ZEBU_ROOT)/include -I$(ZCUIWORK)/zebu.work -I$(ZCUIWORK)/zebu.work/zemi3
LIBS=-L$(ZEBU_ROOT)/lib -lZebu -lZebuZEMI3
SWITCH=-D_GLIBCXX_USE_CXX11_ABI=1 
#ZEMI3FILE=$(ZCUIWORK)/zebu.work/dpi_xtor.so 
ZEMI3FILE= 

tb.o: 
	$(CXX) $(CXXFLAGS) -fPIC -o tb.o $(INCL_PATH) $(LIBS) -c tb.cc 

compile_tb: tb.o
	\rm -rf ZRCI_1/ zLicenseManager.rt001.*.log zRci.rt001.0.log zServer.rt001.0.log simzilla_3054108.log* profiler.rt001.*
	-cd $(ZCUIWORK)/backend_default && make -f dpixtor.mk 
	make -C zcui.work/zebu.work -f grp0_ccall.mk clean comp
	$(CXX) $(CXXFLAGS) -g -shared -o tb.so $(INCL_PATH) $(LIBS)  $(SWITCH) tb.o 

run: compile_tb
	zRci run.ucli

