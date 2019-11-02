#include <unistd.h>

int usleep(useconds_t usec)
{
	Sleep((usec + (1000 - 1)) / 1000);
	return 0;
}
