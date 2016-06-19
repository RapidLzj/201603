"""
    Call data reduce pipeline for pass2
    2016-06-18
"""

import os
import MySQLdb


def bok_one(filename):
    """ Generate reduce command and call IDL. """

    part = filename.split("/")
    run = part[5]
    mjd = part[6]
    flt = part[4]
    typ = part[7]
    bare = part[8][0:10]

    bias_file = "/data/red/bok/@/pass2/%s/J%d/bias.fits" % (run, mjd)
    flat_file = "/data/red/bok/%s/pass2/%s/J%d/bias.fits" % (flt, run, mjd)

    sci_path = "/data/red/bok/%s/pass2/%s/J%d/%s/" % (flt, run, mjd, typ)
    raw_path = os.path.dirname(filename)

    cmd = "idl pip_shell.pro -args B %s %s %s %s %s" % (
        raw_path, sci_path, bare, bias_file, flat_file)
    print (cmd)
    os.system(cmd)



if __name__ == "__main__" :
    conn = MySQLdb.connect('localhost', 'uvbys', 'uvbySurvey', 'surveylog')
    cur = conn.cursor()

    sql = "select FileName FROM FileBasic where Telescope='B' and Type in ('S','O') and MJD >= 7330"
    cur.execute(sql)
    dr_file = cur.fetchall()

    for row in dr_file:
        filename = row[0]
        bok_one(filename)
        break

    cur.close()
    conn.close()
    print ("DONE")
