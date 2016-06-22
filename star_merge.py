"""
    Merge stars from table
"""

import MySQLdb
from star_match import star_match


if __name__ == "__main__" :

    conn = MySQLdb.connect("localhost", "uvbys", "uvbySurvey", "survey")
    cur = conn.cursor()

    # TODO: merge stars (lzj)

    # load stars from SDSSnearM67
    # load files from m67
    # load stars from each file
    # match my stars with sdss stars
    # save all matched stars into new table

    sql_sdss = "select ObjID, RAdeg, Decdeg, magu from SDSSnearM67"
    cur.execute(sql_sdss)
    tb_sdss = cur.fetchall()
    print ("%d Stars from SDSS" % (cur.rows_count))

    sql_m67 = "select fileid, filtercode, exptime, (select count(*) from Stars where fileid=m67.fileid) as cnt from m67"
    cur.execute(sql_m67)
    tb_m67 = cur.fetchall()

    file_id = [row[0] for row in tb_m67 if row[3] > 0]
    filter_code = [row[1] for row in tb_m67 if row[3] > 0]
    exp_time = [row[2] for row in tb_m67 if row[3] > 0]
    star_cnt = [row[3] for row in tb_m67 if row[3] > 0]

    sql_ins0 = "insert into m67_match(my_star_code, sdss_obj_id, distance) values('%s', '%s', %f)"

    for f in file_id :
        sql_my = "select StarCode, RADeg, DecDeg, MagAuto, MagCorr, MagAutoErr from Stars where FileID = '%s'" % f
        n_my = cur.execute(sql_my)
        tb_my = cur.fetchall()
        #my_ra = [row[1] for row in tb_my]
        #my_dec = [row[2] for row in tb_my]
        #plt.plot(my_ra, my_dec, '.')
        ix_sdss, ix_my, dis_sdss_my = star_match(tb_sdss, tb_my, 1, 2, 1, 2, 3, 3)
        n_match = len(ix_sdss)
        #print (len(ix_my))
        #plt.plot(sdss_ra[ix_sdss], sdss_dec[ix_sdss], '.')
        for i in range(n_match) :
            sql = sql_ins0 % (tb_my[ix_my[i]][0], tb_sdss[ix_sdss[i]][0], dis_sdss_my[i])
            cur.execute(sql)
        conn.commit()
        print ("File %s | %5d stars | %5d matched" % (f, n_my, n_match))

    cur.close()
    conn.close()
    print ("END")