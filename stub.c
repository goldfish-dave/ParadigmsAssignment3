#include <stdlib.h>

#define align(s,a) (((size_t)(s) + ((a) - 1)) & ~((size_t) (a) - 1))

#define SSE_ALIGN (16)

#define NUM (100)

extern void mymin(long, float *, float *, float *);

int main (void) {
	float *a = malloc(sizeof(float)*NUM + SSE_ALIGN),
		  *b = malloc(sizeof(float)*NUM + SSE_ALIGN),
		  *c = malloc(sizeof(float)*NUM + SSE_ALIGN);
	int i;

	a = (float *) align(a, SSE_ALIGN);
	b = (float *) align(b, SSE_ALIGN);
	c = (float *) align(c, SSE_ALIGN);

	for (i = 0; i < NUM; i++) {
		a[i] = i;
		b[i] = NUM - i;
	}

	mymin(NUM, a, b, c);

	for (i = 0; i < NUM; i++) {
		//printf(c[i]);
	}

	return 0;
}
