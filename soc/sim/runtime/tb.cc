// Common and ZEBU
#include "libZebu.hh"
#include "zRci.hh"
#include <iomanip>
#include <thread>
#include <assert.h>
#include <sstream>
#include <string.h>
#include <iostream>
#include <atomic>
#include <mutex>
#include <queue>
#include "svdpi.h"
#include"libZebuZEMI3.hh"
#include <unistd.h>
#include <stdexcept>
#include <exception>
#include <stdlib.h>
#include <signal.h>
#include "ZEMI3Xtor.hh"
#include <sys/time.h>

// Namespaces
using namespace std;
using namespace ZRCI;
using namespace ZEBU;

Board *board = NULL; 

extern "C" int add_values (int a);

extern "C" void print_counter(int *counter) {
	printf("Value of counter is %d\n", *counter);
}

void* zRci_pre_board_open(const ZRCI::TbOpts& tb0pts) {
	printf("===============================\n");
	printf("     zRci_pre_board_open      \n");
	printf("===============================\n");
	
	return NULL;
}

void* zRci_post_board_open(const ZRCI::TbOpts& tb0pts) {
	printf("===============================\n");
	printf("      zRci_post_board_open     \n");
	printf("===============================\n");
	
	board = tb0pts.board;

	return NULL;
}

void* zRci_pre_board_init(const ZRCI::TbOpts& tb0pts) {
	printf("===============================\n");
	printf("      zRci_pre_board_init      \n");
	printf("===============================\n");
	
	printf ("Initializing ZEMI3 XTORs\n");
	
	return NULL;
}


void* zRci_post_board_init(const ZRCI::TbOpts& tb0pts) {
	printf("===============================\n");
	printf("      zRci_post_board_init     \n");
	printf("===============================\n");
	
	return NULL;
}

void* zRci_cleanup(const ZRCI::TbOpts& tb0pts) {
	printf("=====================================\n");
	printf("          zRci_cleanup start         \n");
	printf("=====================================\n");
	
	return NULL;
}

std::string zRci_command(const std::string& key, const std::string& value) {
	printf("===============================\n");
	printf("          zRci_command         \n");
	printf("===============================\n");

	if (key == "usercb"){
		printf("Entering proc\n");
		svScope s = svGetScopeFromName("dut.dpi_xtor_inst");
		svSetScope(s);
		int result = add_values(1);
		fprintf(stdout, "Result of add_values is: %d\n",result);
	}

	return key;
}
