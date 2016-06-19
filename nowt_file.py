import os
import pyfits
import MySQLdb
import time

def insnowt (mjd, objtype, fits, cur) :
    if os.path.getsize(fits) != 34424640 : return
    print fits
    hdulist = pyfits.open(fits)
    hdr = hdulist[0].header
    dt = hdr['date-obs']
    yr = int(dt[0:4]); mn = int(dt[5:7]); dy = int(dt[8:10]); hr = int(dt[11:13]); mi = int(dt[14:16]); se = int(dt[17:19])
    ss = time.mktime((yr, mn, dy, hr, mi, se, 0, 0, 0)) - time0
    #mjd = int(ss / 60 / 60 / 24)
    hr24 = hr
    if hr < 4 : hr24 = hr + 24 
    tim = (hr24 + 8 - 12) * 3600 + mi * 60 + se
    sn = int(hdr['obsnum'])
    if mjd == 7051 and hr24 < 13 and sn > 100 : sn+=9000
    if mjd == 7009 and hr24 < 14 and sn > 60 : sn +=9000
    if mjd == 7010 and se == 15 : sn += 9000
    if mjd == 7017 and objtype == 'BIAS' : sn+=9000
    if mjd == 7134 and objtype == 'BIAS' and sn < 100 : sn+=9000
    if mjd == 7382 and objtype == 'FLAT' and sn == 154 : sn+=9000
    if mjd == 7022 and sn == 6 and se == 3 : sn = 16
    if mjd == 7022 and sn == 141 and mi == 10 : sn += 9000
    if mjd == 6752 and sn == 2 and mi == 46 : sn += 9000
    obj = hdr['object'].strip()
    fil = hdr['filter'].strip()
    ext = float(hdr['exptime'])
    try : 
        ra  = float(hdr['objctra']) * 15.0
    except :
        ra = 0.0
    try : 
        dec = float(hdr['objctdec'])
    except :
        dec = 0.0
    fid = '%4.4dN%4.4d'%(mjd, sn)
    sql = "INSERT INTO ObsFileBasic (FileID, MJD, ObsTime, SN, ObjType, Object, Filter, ExpTime, RADeg, DecDeg, Tag, FileName, Note) " + \
          "VALUES ('%s', %d, %d, %d, '%s', '%s', '%s', %f, %f, %f, 0, '%s', '')" % \
          (fid, mjd, tim, sn, objtype, obj, fil, ext, ra, dec, fits)
    try :
        cur.execute(sql)
    except:
        print sql
        exit()

db = MySQLdb.connect('localhost', 'uvbys', 'uvbySurvey', 'survey')
cur = db.cursor()

basepath = '/data/raw/XAO/'

time0 = time.mktime((1995,10,10,12,0,0,0,0,0)) #JD 2450000.5

runs = [basepath+p+'/' for p in os.listdir(basepath) if os.path.isdir(basepath+p)]
for run in runs :

    days = [p for p in os.listdir(run) if os.path.isdir(run+p)]
    
    for day in days :

        yr = int(day[0:4]); mn = int(day[4:6]); dy = int(day[6:8])
        mjd = (time.mktime((yr, mn, dy, 12, 0, 0, 0, 0, 0)) - time0) / 60 / 60 / 24
        print 'J%4.4d : %s' % (mjd, day)
        dayp = run+day+'/'

        pp = dayp+'BIAS/'
        if os.path.exists(pp) :
            ff = [pp+f for f in os.listdir(pp) if os.path.isfile(pp+f)]
            for f in ff :
                insnowt(mjd, 'BIAS', f, cur)
            db.commit()

        pp = dayp+'FLAT/'
        if os.path.exists(pp) :
            ff = [pp+f for f in os.listdir(pp) if os.path.isfile(pp+f)]
            for f in ff :
                insnowt(mjd, 'FLAT', f, cur)
            db.commit()

        pp = dayp+'uvby_survey/'
        if os.path.exists(pp) :
            oo = [pp+f+'/' for f in os.listdir(pp) if os.path.isdir(pp+f)]
            for o in oo :
                ff = [o+f for f in os.listdir(o) if os.path.isfile(o+f)]
                for f in ff :
                    insnowt(mjd, 'OBJECT', f, cur)
                db.commit()


db.close()

