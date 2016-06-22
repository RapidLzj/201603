"""
    Check files for their overlap
"""

import MySQLdb
import math


if __name__ == "__main__" :
    conn = MySQLdb.connect("localhost", "uvbys", "uvbySurvey")
    cur = conn.cursor()

    dec_size = 1.2 / 2

    sql_all = "select FileID, RADeg, DecDeg, Telescope, FilterCode, Object, ExpTime " +\
              "from surveylog.FileBasic where Type in ('O','S')"
    cur.execute(sql_all)
    file_all = cur.fetchall()

    sql_over0 = "select FileID, RADeg, DecDeg, Telescope, FilterCode, Object, ExpTime from surveylog.FileBasic " + \
                "where Type in ('O','S') and FileID <> '%s' and " + \
                "RADeg between %f and %f and DecDeg between %f and %f"

    sql_ins0 = "insert into survey.FileOverlap(FileID1, FileID2, RADeg1, DecDeg1, RADeg2, DecDeg2, " +\
               "Object1, Object2, Filter1, Filter2, OverlapLevel) values " +\
               "('%s', '%s', %f,%f, %f, %f, '%s', '%s', '%s', '%s', %d)"

    for file1 in file_all:
        ra_scale = math.cos(file1[2] / 180.0 * math.pi)
        ra_size = dec_size / ra_scale
        print ("%9s (%8.4f %8.4f) <%-10s> [%1s %3d]" % (file1[0], file1[1], file1[2], file1[5], file1[4], file1[6]))

        sql_over = sql_over0 % (file1[0],
                                file1[1] - ra_size, file1[1] + ra_size,
                                file1[2] - dec_size, file1[2] + dec_size)
        cur.execute(sql_over)
        file_over = cur.fetchall()

        for file2 in file_over:
            ra_dis = abs(file1[1] - file2[1]) * ra_scale
            dec_dis = abs(file1[2] - file2[2])
            level = (1 if file1[3] == file2[3] else 0) + \
                    (2 if file1[4] == file2[4] else 0) + \
                    (4 if file1[6] == file2[6] else 0) + \
                    (8 if ra_dis < 0.15 and dec_dis < 0.15 else 0) + \
                    (16 if ra_dis < 0.3 else 0) + \
                    (32 if dec_dis < 0.3 else 0)
            print ("            |%s| %9s (%8.4f %8.4f) <%10s> [%1s %3d]" %
                   (bin(128 + level)[4:], file2[0], file2[1], file2[2], file2[5], file2[4], file2[6]))

            sql_ins = sql_ins0 % (file1[0], file2[0],
                                  file1[1], file1[2], file2[1], file2[2],
                                  file1[5], file2[5], file1[4], file2[4],
                                  level)
            cur.execute(sql_ins)
        conn.commit()

    cur.close()
    conn.close()
    print ("DONE")
