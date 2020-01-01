from distutils.core import setup, Extension
setup(name = 'swgcd', version = '1.0', ext_modules = [Extension('swgcd', ['sw_gcd.c'])])
