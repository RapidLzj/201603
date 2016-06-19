'''
    Utilities by lzj
    Transfer between Sexagesimal and Decimal
    Modified Julian Day Calculator, substration to 1995-10-10
    fits header field read, include exception handle
'''
# Author: lzj, 20160513, Tucson

import time
from math import isnan, isinf

def tryfloat (s, default=0.0, allownan=True) :
    try :
        res = float(s)
    except :
        res = default
    if not allownan :
        if isnan(res) or isinf(res) :
            res = default
    return (res)

def tryint (s, default=0) :
    try :
        res = int(s)
    except :
        res = default
    return (res)

def sex2dec (s) :
    # remove space
    q = s.strip()
    if q == '' : return (999.99999)
    # sign check and remove
    if q[0] == '+' :
        p = 1
        q = q[1:]
    elif q[0] == '-' :
        p = -1
        q = q[1:]
    else :
        p = 1
    # h m s split
    hms = q.split()
    if len(hms) == 1 : hms = q.split(':')
    h = m = s = 0.0
    h = tryfloat(hms[0])
    if len(hms) >= 2 : m = tryfloat(hms[1])
    if len(hms) >= 3 : s = tryfloat(hms[2])
    # merge
    res = p * (h + m / 60.0 + s / 3600.0)
    return(res)

def dec2sex (d, withsign=True, secplace=2) :
    # sign
    sign = ''
    if withsign : sign = '+'
    if d < 0 : sign = '-'
    dd = abs(d)
    # hms split
    ss = dd * 3600.0
    h = ss // 3600
    m = ss // 60 - h * 60
    s = int(ss - h * 3600 - m * 60)
    ms = int((ss - int(ss)) * 1000)
    # merge
    if secplace <= 0 :
        ms2 = ''
    else :
        if secplace >= 3 : secplace = 3
        ms2 = '.' + ('%3.3d' % ms)[0:secplace]
    res = '%s%2.2d:%2.2d:%2.2d%s' % (sign, h, m, s, ms2)
    return(res)

_time0 = time.mktime((1995, 10, 10, 0, 0, 0, 0, 0, 0)) # 2450000.5

def mjd (yr, mn, dy, hr=0, mi=0, se=0, tz=0) :
    t = time.mktime((yr, mn, dy, hr-tz, mi, se, 0, 0, 0))
    res = (t - _time0) / 60.0 / 60.0 / 24.0
    return (res)

def cal (mjd) :
    t = mjd * 60.0 * 60.0 * 24.0 + _time0
    ts = time.gmtime(t)[0:6]
    return (ts)

def hdr (header, key, default='') :
    try :
        res = header[key]
    except :
       res = default
    return (res)

