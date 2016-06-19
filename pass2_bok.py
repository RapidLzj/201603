"""
    Call bias merge for pass2
    2016-06-18
"""

import os
import MySQLdb


def bok_one(run, mjd, flt, typ, filename) :
    """ Generate reduce command and call IDL. """

    run_path = run[0:6] if run[6] == "_" else run[0:7]
    type_path = "good" if typ == "S" else "other"

    bias_file = "/data/red/bok/@/pass2/%s/J%d/bias.fits" % (run_path, mjd)
    flat_file = "/data/red/bok/%s/pass2/%s/J%d/bias.fits" % (flt, run_path, mjd)

    sci_path = "/data/red/bok/%s/pass2/%s/J%d/%s/" % (flt, run_path, mjd, type_path)

    cmd = "idl flat_shell2.pro -args %s %s %s" % (fn_lst, out_bias, out_flat)
    print (cmd)
    os.system(cmd)



if __name__ == "__main__" :
    conn = MySQLdb.connect('localhost', 'uvbys', 'uvbySurvey', 'surveylog')
    cur = conn.cursor()

    sql = "select RunID, MJD, Type, FilterCode, from FileBasic where substr(NightID, 5, 1)='B' and MJD >= 7331"
    cur.execute(sql)
    dr_night = cur.fetchall()

    for one_night in dr_night:
        run = one_night[0]
        mjd = one_night[1]
        bias_flat(run, mjd, cur)
        

    cur.close()
    conn.close()
    print ("DONE")
