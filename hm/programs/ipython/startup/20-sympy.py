#!/usr/bin/env python3

try:
    from sympy import *
except ImportError:
    pass
else:
    init_printing()
#    from sympy.abc import p,q,t,k

#    x, y, z, a, b, c, p, q, t = symbols("x y z a b c p q t", real=True)
#    m, n = symbols("m n", integer=True)
#    k = symbols("k", real=True)


#    dx = lambda f: diff(f, x)
#    dy = lambda f: diff(f, y)
#    dt = lambda f: diff(f, t)

#    e = E
    R = Rational
    V = lambda *x: Matrix(x)
    M = lambda *cols: Matrix([[Matrix(col) for col in cols]])

#    xy = Matrix([ x, y ])
#    xyz = Matrix([ x, y, z ])
#
#    def grad(f, variables=None):
#        """
#        Grad operator
#        """
#        if variables is None:
#            variables = f.free_symbols
#
#        return Matrix([diff(f, x) for x in variables])
#
#    def C(n, r):
#        """
#        nCr
#        """
#        return factorial(n)/factorial(r)/factorial(n-r)
#
#    def divergence(f, x):
#        """
#        Divergence of f
#        """
#        if len(x) != len(f):
#            raise ValueError(f"differing number of dimensions, f: {len(f)}, x: {len(x)}")
#
#        return sum([diff(fi, xi) for fi, xi in zip(f, variables)])
#
#    def curl(f, x=xyz):
#        """
#        3d curl of vector
#        """
#        if len(f) != 3:
#            raise ValueError("field must be 3-dimensional")
#
#        return Matrix([
#            diff(f[2], x[1]) - diff(f[1], x[2]),
#            diff(f[0], x[2]) - diff(f[2], x[0]),
#            diff(f[1], x[0]) - diff(f[0], x[1]),
#        ])
#
#    def J(f, x):
#        """
#        Jacobian matrix
#        """
#        return Matrix([[diff(fi, xi) for xi in x] for fi in f])
