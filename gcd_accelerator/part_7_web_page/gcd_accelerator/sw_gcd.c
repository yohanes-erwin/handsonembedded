#include <Python.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <time.h>

int fd;
static volatile uint32_t *perf_cnt_p;

unsigned int gcd(unsigned int a, unsigned int b,  unsigned int *clks)
{
    uint8_t n = 0;
    uint32_t overhead = 0;

    // *** Map the physical address of AXI performance counter to the virtual address ***
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    perf_cnt_p = (uint32_t *)mmap(0, getpagesize(), PROT_READ | PROT_WRITE,
            MAP_SHARED, fd, 0x42000000);

    // *** Determine the overhead of accessing the AXI performance counter ***
    *(perf_cnt_p+0) = 0x1;  // Start
    *(perf_cnt_p+0) = 0x1;  // Start
    *(perf_cnt_p+0) = 0x2;  // Stop
    overhead = *(perf_cnt_p+1);

    // *** Start actual measurement ***
    *(perf_cnt_p+0) = 0x1;  // Start
    while (1)
    {
        if (a == b)
            break;
        if ((a % 2) == 0)       // a even
        {
            a = a >> 1;
            if ((b % 2) == 0)   // b even
            {
                b = b >> 1;
                n++;
            }
        }
        else                    // a odd
        {
            if ((b % 2) == 0)   // b even
                b = b >> 1;
            else                // b odd
            {
                if (a > b)
                    a = a - b;
                else
                    b = b - a;
            }
        }
    }
    a = a << n;
	*(perf_cnt_p+0) = 0x2;  // Stop
	*clks = *(perf_cnt_p+1) - overhead;     // Read performance counter

    return a;
}

static PyObject* sw_gcd(PyObject* self, PyObject* args)
{
    unsigned int a, b, c, clks;

    if (!PyArg_ParseTuple(args, "II", &a, &b))
        return NULL;

    c = gcd(a, b, &clks);

    PyObject* py = PyTuple_New(2);
    PyTuple_SET_ITEM(py, 0, Py_BuildValue("I", c));
    PyTuple_SET_ITEM(py, 1, Py_BuildValue("I", clks));

    return py;
}

static PyMethodDef myMethods[] = {
    { "sw_gcd", sw_gcd, METH_VARARGS, "Calculate GCD in C." },
    { NULL, NULL, 0, NULL }
};

static struct PyModuleDef myModule = {
    PyModuleDef_HEAD_INIT,
    "swgcd",
    "This module provides an interface for calculating GCD in C.",
    -1,
    myMethods
};

PyMODINIT_FUNC PyInit_swgcd(void)
{
    return PyModule_Create(&myModule);
}
