// Author: Erwin Ouyang
// Date  : 5 Feb 2019

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

unsigned int calc_gcd_sw(unsigned int a, unsigned int b, unsigned int *clks);
unsigned int calc_gcd_hw(unsigned int a, unsigned int b, unsigned int *clks);

int main()
{
	unsigned int a, b;
	unsigned int r_sw, r_hw;
	unsigned int sw_clks, total_sw_clks;
	unsigned int hw_clks, total_hw_clks;
	unsigned int samples = 10000;

	printf("HW/SW comparison of GCD algorithm:\n");
	for (int i = 0; i < samples; i++)
	{
		a = rand() + 1;
		b = rand() + 1;
		r_sw = calc_gcd_sw(a, b, &sw_clks);
		r_hw = calc_gcd_hw(a, b, &hw_clks);
		if (r_sw != r_hw)
			printf("Inconsistency: gcd(%d,%d)=%d/%d\n", a, b, r_sw, r_hw);
		total_sw_clks += sw_clks;
		total_hw_clks += hw_clks;
	}
	printf("Average clocks (software/hardware) = %d/%d\n",
			total_sw_clks/samples, total_hw_clks/samples);
	printf("Hardware accelerator speed up = %.2f\n",
			(double)total_sw_clks/total_hw_clks);

	return 0;
}

unsigned int calc_gcd_sw(unsigned int a, unsigned int b, unsigned int *clks)
{
	uint32_t *perf_cnt_p;
	uint8_t n = 0;
	unsigned int overhead;

	// Initialize pointer to AXI performance counter
	perf_cnt_p = (uint32_t *)0x42000000;

	// *** Determine the overhead of accessing the AXI performance counter ***
	*(perf_cnt_p+0) = 0x1;	// Start
	*(perf_cnt_p+0) = 0x2;	// Stop
	overhead = *(perf_cnt_p+1);

	// *** Start actual measurement ***
	*(perf_cnt_p+0) = 0x1;	// Start
	while (1)
	{
		if (a == b)
			break;
		if ((a % 2) == 0)		// a even
		{
			a = a >> 1;
			if ((b % 2) == 0)	// b even
			{
				b = b >> 1;
				n++;
			}
		}
		else					// a odd
		{
			if ((b % 2) == 0)	// b even
				b = b >> 1;
			else				// b odd
			{
				if (a > b)
					a = a - b;
				else
					b = b - a;
			}
		}
	}
	a = a << n;
	*(perf_cnt_p+0) = 0x2;	// Stop
	*clks = *(perf_cnt_p+1) - overhead;		// Read performance counter

	return a;
}

unsigned int calc_gcd_hw(unsigned int a, unsigned int b, unsigned int *clks)
{
	uint32_t *gcd_p;

	// Initialize pointer to AXI GCD
	gcd_p = (uint32_t *)0x41000000;

    // *** Calculate hardware GCD ***
	*(gcd_p+1) = a;
	*(gcd_p+2) = b;
	*(gcd_p+0) = 0x1;	// Start
	while (!(*(gcd_p+0) & (1 << 1)));	// Wait until done flag is set
	*clks = *(gcd_p+4);					// Read performance counter

	return *(gcd_p+3);
}
