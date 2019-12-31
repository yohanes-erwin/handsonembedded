// Author: Erwin Ouyang
// Date  : 5 Feb 2019

#include <stdio.h>
#include <stdint.h>

uint32_t *gcd_p;

int main()
{
	// *** Pointer to AXI GCD ***
	gcd_p = (uint32_t *)0x41000000;

    // *** Calculate gcd(35,25) ***
	*(gcd_p+1) = 35;	// A = 35
	*(gcd_p+2) = 25;	// B = 35
	*(gcd_p+0) = 0x1;	// START = 1
	while (!(*(gcd_p+0) & (1 << 1)));	// Wait until done flag is set
	printf("GCD(35, 25) = %d\n", (unsigned int)*(gcd_p+3));

    // *** Calculate gcd(252,76) ***
	*(gcd_p+1) = 128;	// A = 128
	*(gcd_p+2) = 72;	// B = 72
	*(gcd_p+0) = 0x1;	// START = 1
	while (!(*(gcd_p+0) & (1 << 1)));	// Wait until done flag is set
	printf("GCD(128, 72) = %d\n", (unsigned int)*(gcd_p+3));

	return 0;
}
