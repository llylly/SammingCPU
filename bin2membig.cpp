#include <cstdio>

int main(int argc, char** argv) {
	freopen(argv[1], "r", stdin);
	freopen(argv[2], "w", stdout);
	unsigned char c;
	unsigned int x;
	while (scanf("%c", &c) != EOF) {
		x = 0;
		x += ((unsigned int)c);
		scanf("%c", &c);
		x += ((unsigned int)c) << 8;
		scanf("%c", &c);
		x += ((unsigned int)c) << 16;
		scanf("%c", &c);
		x += ((unsigned int)c) << 24;
		printf("%08x\n", x);
	}
	return 0;
}