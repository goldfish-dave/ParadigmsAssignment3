#include <stdlib.h>
#include <stdio.h>
#define align(s,a) (((size_t)(s) + ((a) - 1)) & ~((size_t) (a) - 1))

#define SSE_ALIGN (16)

#define NUM (10)

extern void mymin(long, float *, float *, float *);

int main (void) {
	float *a = malloc(sizeof(float)*NUM + SSE_ALIGN),
		  *b = malloc(sizeof(float)*NUM + SSE_ALIGN),
		  *c = malloc(sizeof(float)*NUM + SSE_ALIGN);

	a = (float *) align(a, SSE_ALIGN);
	b = (float *) align(b, SSE_ALIGN);
	c = (float *) align(c, SSE_ALIGN);

/*	for (i = 0; i < NUM; i++) {
		a[i] = i;
		b[i] = NUM - i;
	}
*/	
	*a = (float) 123;
	printf("before mymin()\na = %f\nb = %f\nc = %f\n", a[0], b[0], c[0]);
	mymin(NUM, a, b, c);
		
	printf("after mymin()\na = %f\nb = %f\nc = %f", a[0], b[0], c[0]);

	return 0;
}
