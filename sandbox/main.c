#include <stdio.h>

void lib_test(void);
int fmain(int i, char** c);

#define TEST_REPEAT 10
int main(int argc, char** argv)
{
	int i;
	for (i = 0; i < TEST_REPEAT; i++)
	{
		//fmain(0, 0);
		lib_test();
	}
	
//	getchar();
	return 0;
}