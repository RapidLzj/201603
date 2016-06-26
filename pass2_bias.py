"""
    Call bias merge for pass2
    2016-06-18
"""

import os
import MySQLdb


def bias_flat(run, mjd, cur) :
    """ Generate bias and flat command and call IDL. """

    if run[6] == "_" :
        run_path = run[0:6]
    else :
        run_path = run[0:7]

    out_bias_path = "/data/red/bok/@/pass2/%s/J%d/" % (run_path, mjd)
    out_bias = out_bias_path + "bias.fits"

    if not os.path.isfile(out_bias):
        os.system("mkdir -p %s" % out_bias_path)

        sql = ("select FileName from FileBasic where MJD = %d and Telescope = 'B' and Type = 'B'"
               % mjd)
        print (sql)
        cur.execute(sql)
        dr_file = cur.fetchall()
        fn_lst = "lst2/bias_%d.lst" % mjd
        f_lst = open(fn_lst, "w")
        for f in dr_file:
            f_lst.write(f[0] + "\n")
        f_lst.close()

        cmd = "idl bias_shell2.pro -args %s %s" % (fn_lst, out_bias)
        print (cmd)
        os.system(cmd)

    for fil in ['u', 'v']:
        out_flat_path = "/data/red/bok/%s/pass2/%s/J%d/" % (fil, run_path, mjd)
        out_flat = out_flat_path + "flat.fits"
        #if not os.path.isfile(out_flat):
        if True :
            os.system("mkdir -p %s" % out_flat_path)

            sql = ("select FileName from FileBasic where MJD = %d and FilterCode = '%s' and Telescope = 'B' and Type = 'F'"
                   % (mjd, fil))
            print (sql)
            cur.execute(sql)
            dr_file = cur.fetchall()
            fn_lst = "lst2/flat_%s_%d.lst" % (fil, mjd)
            f_lst = open(fn_lst, "w")
            for f in dr_file:
                f_lst.write(f[0] + "\n")
            f_lst.close()

            cmd = "idl flat_shell2.pro -args %s %s %s" % (fn_lst, out_bias, out_flat)
            print (cmd)
            os.system(cmd)



if __name__ == "__main__" :
    conn = MySQLdb.connect('localhost', 'uvbys', 'uvbySurvey', 'surveylog')
    cur = conn.cursor()

    sql = "select RunID, MJD from ObsNight where substr(NightID, 5, 1)='B' and MJD >= 7331"
    cur.execute(sql)
    dr_night = cur.fetchall()

    for one_night in dr_night:
        run = one_night[0]
        mjd = one_night[1]
        bias_flat(run, mjd, cur)
        

    cur.close()
    conn.close()
    print ("DONE")
