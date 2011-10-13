#include <stdlib.h>
#include <stdio.h>
#define align(s,a) (((size_t)(s) + ((a) - 1)) & ~((size_t) (a) - 1))

#define SSE_ALIGN (16)

#define NUM (10)

//extern void mymin(long, float *, float *, float *);
extern void myAddMult(long, float *, float *, float *);
extern void myadd(long, float *, float *, float *);

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
		c[i] = 0;
	}
	
	*a = (float) 123;
	printf("Before:\n");
	for (i = 0; i < NUM; i++) {
		printf("%f \t %f \t %f\n", a[i], b[i], c[i]);
	}
	//printf("before mymin()\na = %f\nb = %f\nc = %f\n", a[0], b[0], c[0]);
	//mymin(NUM, a, b, c);
	myadd(NUM, a,b,c);
		
	//printf("after mymin()\na = %f\nb = %f\nc = %f", a[0], b[0], c[0]);
	printf("After:\n");
	for (i = 0; i < NUM; i++) {
		printf("%f \t %f \t %f\n", a[i], b[i], c[i]);
	}

	return 0;
}
