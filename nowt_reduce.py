import os
#import pyfits
import MySQLdb
import time
import lzjutil as lzju

def insnowtred (cur, fileid, mjd, fil, filename) :

    baselist = {'u':'/data/red/XAO/u/pass1/',
        'v':'/data/red/XAO/v/pass1/',
        'b':'/data/red/XAO/b/pass1/',
        'y':'/data/red/XAO/y/pass1/',
        'w':'/data/red/XAO/Hw/pass1/',
        'n':'/data/red/XAO/Hn/pass1/',
        }
    if not baselist.has_key(fil) : return (0)
    basepath = baselist[fil]

    filepart = filename.split('/')
    basename = filepart[8][0:-5]
    caldate = '%4.4d%2.2d%2.2d' % lzju.cal(mjd)[0:3]

    redpath = basepath+filepart[4]+'/'+filepart[5]+'/good/'+basename+'/'
    dbfile = redpath+basename+'.db.txt'
    if not os.path.exists(dbfile) :
        redpath = basepath+filepart[4]+'/'+filepart[5]+'/other/'+basename+'/'
        dbfile = redpath+basename+'.db.txt'
        if not os.path.exists(dbfile) :
            return (0)
    #print filename, dbfile

    # reduce time (file create time)
    rtimef = os.path.getctime(dbfile)
    rtimes = time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime(rtimef))

    # reduce result
    f = open(dbfile, 'r')
    line = f.readline()
    line = f.readline()
    f.close()
    part = (': '+line).split()  # add a leading part, make index from 1

    if int(part[33]) > 0 :
        laststep = 4
    elif int(part[8]) > 0 :
        laststep = 3
    elif int(part[28]) > 0 :
        laststep = 2
    else :
        laststep = 1

    fld = [lzju.tryfloat(v, allownan=False) for v in part]

    sql = "INSERT INTO FileReduceResult (FileID, Version, ReduceTime, LastStep, " + \
          "NStar, FwhmMed, FwhmSig, ElongMed, ElongSig, " + \
          "Azi , Alt , AirMass, MoonPhase, MoonAngle, MoonAlt, " + \
          "NWcs, MagWcs, NewRA, NewDec, CorRA, CorDec, " + \
          "NMag, MagConst, MagErr, " + \
          "Mag5, Mag10, Mag33, Mag50, Mag100, Mag333, " + \
          "SkyMag, SkyErr, " +\
          "FilePath) " + \
          "VALUES ('%s', 1, '%s', %d, " + \
          "%i, %f, %f, %f, %f, " + \
          "%f, %f, %f, %f, %f, %f, " + \
          "%i, %f, %f, %f, %f, %f, " + \
          "%i, %s, %s, " + \
          "%f, %f, %f, %f, %f, %f, " + \
          "%f, %f, " + \
          "'%s')"
    sql = sql % (fileid, rtimes, laststep, \
        fld[28], fld[29], fld[30], fld[31], fld[32], \
        fld[22], fld[23], fld[24], fld[25], fld[27], fld[26], \
        fld[ 8], fld[ 9], fld[18], fld[19], fld[20], fld[21], \
        fld[33], fld[34], fld[35], \
        fld[36], fld[37], fld[38], fld[39], fld[40], fld[41], \
        fld[44], fld[45], \
        redpath)
    #print sql
    try :
        cur.execute(sql)
    except:
        print sql
        exit()
    return (laststep)

# main program

if __name__ == '__main__' :

    db = MySQLdb.connect('localhost', 'uvbys', 'uvbySurvey', 'survey')
    cur = db.cursor()

    cur.execute("SELECT FileID, MJD, FilterCode, FileName FROM ObsFileBasic " + \
        "WHERE Telescope='N' AND (Type='S' OR Type='O') ORDER BY FileID")
    tb = cur.fetchall()
    cc=0
    for row in tb :
        ls=insnowtred (cur, row[0], row[1], row[2], row[3])
        cc += (1 if ls > 0 else 0)
        db.commit()
        #if cc == 50 : break

    db.close()
    print 'DONE', cc
