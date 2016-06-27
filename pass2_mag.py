"""
    2016-06-26
    Mag calibration using fitted u from APASS catalog
"""

import os
import sys
import MySQLdb


def bok_one(filename):
    """ Generate reduce command and call IDL. """

    part = filename.split("/")
    run = part[5]
    mjd = part[6]
    flt = part[4]
    typ = part[7]
    bare = part[8][0:10]

    bias_file = "/data/red/bok/@/pass2/%s/%s/bias.fits" % (run, mjd)
    flat_file = "/data/red/bok/%s/pass2/%s/%s/flat.fits" % (flt, run, mjd)

    sci_path = "/data/red/bok/%s/pass2/%s/%s/%s/" % (flt, run, mjd, typ)
    raw_path = os.path.dirname(filename)

    cmd = "idl pip_shell_mag.pro -args B %s %s %s %s %s" % (
        raw_path, sci_path, bare, bias_file, flat_file)
    print (cmd)
    os.system(cmd)



if __name__ == "__main__" :
    if len(sys.argv) >= 3 :
        size = sys.argv[2]
        start = sys.argv[1]
    elif len(sys.argv) == 2 :
        size = 800
        start = sys.argv[1]
    else :
        size = 0
        start = 0

    conn = MySQLdb.connect('localhost', 'uvbys', 'uvbySurvey', 'surveylog')
    cur = conn.cursor()

    sql = "select FileName FROM FileBasic where Telescope='B' and Type in ('S','O') and " +\
        "FilterCode = 'u' and MJD >= 7330 and RADeg between 99 and 221 and DecDeg between 19.5 and 28.5"
    if size > 0 :
        sql = "%s limit %s,%s" % (sql, start, size)
    cur.execute(sql)
    dr_file = cur.fetchall()
    print (sql)

    c = 0
    for row in dr_file:
        c += 1
        filename = row[0]
        print (filename)
        bok_one(filename)
        #if c == 12 : break

    cur.close()
    conn.close()
    print ("DONE")
