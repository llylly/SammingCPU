/**
  Booter
  Save in ROM
  2016.12.10
  written by llylly
  Used for loading UCore from Flash to SRAM
*/

char *COMM1 = (char*)0xBFD003F8;

unsigned int *SOURCE = (unsigned int*)0xBE000000, *END = (unsigned int*)0x80000000, *RUN_START = (unsigned int*)0x80000000;

unsigned int COPY_LEN = 4096, UCORE_LEN = 2048;
	// in KB unit

unsigned int ERROR_ADDR = 0xBFC00800, BOOT_ADDR = 0xBFC00000;

void printCh(char c);
void printStr(char *str);

void init() {
	printStr("Samming CPU\n");
	printStr("~~~Energy Moon~~~\n");
	printStr("***** LOADING... *****\n");

	__asm__ __volatile__ (
		".set noreorder;\n"
		"move $v0, %0;\n"
		"mtc0 $v0, $15, 1;\n"
		:
		: "r"(ERROR_ADDR)
		: "v0"
	);
	
	unsigned int *ps = SOURCE, *pe = END;
	int i;
	for (i = 0; i < UCORE_LEN * 256; ++i, ++ps, ++pe) {
		*pe = *ps;
	}
	for (; i < COPY_LEN * 256; ++i, ++pe) {
		*pe = 0;
	}
	printStr("LOADING finish\n");

	__asm__ __volatile__ (
		".set noreorder\n"
		"move $v0, %0;\n"
		"jr $v0;\n"
		:
		: "r"(RUN_START)
		: "v0"
	);
}

void printCh(char c) {
	while (((*(COMM1 + 0x04)) & 0x01) == 0);
	*COMM1 = c;
}

void printStr(char *str) {
	while (*str) printCh(*str), ++str;
}

char readCh() {
	while (((*(COMM1 + 0x04)) & 0x02) == 0);
	return (*COMM1);
}

void error() __attribute__ ((section("err")));

void error() {
	printStr("Boot error.\n");
	printStr("Press R to restart.\n");
	char ch;
	while ((ch = readCh()) != 'R' && ch != 'r') ;
	
	__asm__ __volatile__ (
		".set noreorder\n"
		"move $v0, %0;\n"
		"jr $v0;\n"
		:
		: "r"(BOOT_ADDR)
		: "v0"
	);
}
