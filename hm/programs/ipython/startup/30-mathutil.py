#!/usr/bin/env python3

## def span(*args):
##     matrix = Matrix(args).col_insert(len(args[0]), eye(len(args)))
##     return matrix.echelon_form()
#
#def get_substitution(t, free_symbols):
#    """
#    Helper to get independent variable and substitutions for sympy operations.
#    """
#    if isinstance(t, tuple):
#        # parameter specified
#        if not isinstance(t[0], Symbol):
#            raise ValueError("t[0] must be a variable")
#        var = t[0]
#        subs = [t]
#        return (t[0], [t])
#    else:
#        if not free_symbols:
#            raise ValueError("parametric curve has no free variable")
#        if len(free_symbols) > 1:
#            raise ValueError("parametric variable is ambiguous - must be specified")
#        var = list(free_symbols)[0]
#        subs = [(var, t)]
#    return (var, subs)
#
## TODO make more useful
##
## [x] tangent(f, x0) where f has one free -> curve is y=f
## [ ] tangent(f, (x0, y0)) where f has two free -> curve is implicit f=0
## [x] tangent((fx, fy), t0) where fx and fy have same single free -> curve is parametric (fx, fy)
#def tangent(f, t, normal=False):
#    """
#    Get the tangent to a point on a curve.
#    """
#    if isinstance(f, tuple):
#        if len(f) != 2:
#            raise ValueError("parametric curve must have exactly two expressions")
#        var, subs = get_substitution(t, f[0].free_symbols.union(f[1].free_symbols))
#
#        pt = tuple(x.subs(subs) for x in f)
#        grade = diff(f[1], var)/diff(f[0], var)
#    else:
#        var, subs = get_substitution(t, f.free_symbols)
#
#        pt = (var.subs(subs), f.subs(subs))
#        grade = diff(f, var)
#
#    if normal:
#        grade = -1/grade
#
#    if (1/grade).subs(subs) == 0:
#        return x - pt[0]
#    return simplify(-((y - pt[1]) - grade.subs(subs) * (x - pt[0])))
#
#def polarplot(r, **kwargs):
#    """
#    Polar plot
#    """
#    syms = r.free_symbols
#    if len(syms) > 1:
#        raise ValueError("Too many free symbols")
#    elif not syms:
#        t = symbols('t')
#    else:
#        t = list(syms)[0]
#
#    plot_parametric((r*cos(t), r*sin(t)), (t, 0, 2*pi), axis_center=(0,0), **kwargs)
#
#def taylor(fn, n, where=0):
#    """
#    Generate taylor polynomial of degree n
#    """
#    var, subs = get_substitution(where, fn.free_symbols)
#    about = var.subs(subs)
#    return sum((var - about)**k * diff(fn, var, k).subs(subs) / factorial(k) for k in range(n+1))
#
#def in_span(span, vec):
#    return Matrix([[*span, vec]]).rank() == len(span)
#
#def dv(s):
#    """
#    Digit vector
#    """
#    return Matrix([int(d) for d in s])
#
#def dm(s):
#    """
#    Digit matrix
#    """
#    return Matrix([[int(d) for d in r] for r in s.split()])
