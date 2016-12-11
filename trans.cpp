
#include <cstdio>
#include <cstdlib>
#include <iostream>

using namespace std;

int main() {
	freopen("user.mem", "r", stdin);
	FILE *fp = fopen("user.data", "wb");
	unsigned int tmp; 
	unsigned char c;
	while ((scanf("%x\n", &tmp) > 0)) {
		cout << hex << tmp << endl;
		c = tmp & 0xFF;
		fwrite(&c, sizeof(char), 1, fp);
		tmp >>= 8;
		c = tmp & 0xFF;
		fwrite(&c, sizeof(char), 1, fp);
		tmp >>= 8;
		c = tmp & 0xFF;
		fwrite(&c, sizeof(char), 1, fp);
		tmp >>= 8;
		c = tmp & 0xFF;
		fwrite(&c, sizeof(char), 1, fp);
	}
	fflush(fp);
	fclose(fp);
	return 0;
}