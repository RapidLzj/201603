import os
import pyfits
import MySQLdb
import time
import lzjutil as lzju

def insbok (mjd, objtype, fits, cur) :
    print fits
    hdulist = pyfits.open(fits)
    hdr = hdulist[0].header
    #date = hdr['date']
    loct = lzju.hdr(hdr,'loctime', '00:00:00')
    #yr = int(date[0:4]); mn = int(date[5:7]); dy = int(date[8:10])
    hr = int(loct[0:2]); mi = int(loct[3:5]); se = int(loct[6:8])
    #ss = time.mktime((yr, mn, dy, hr, mi, se, 0, 0, 0)) - time0
    #mjd = int(ss / 60 / 60 / 24)
    hr24 = hr
    if hr < 12 : hr24 = hr + 24 
    tim = (hr24 - 12) * 3600 + mi * 60 + se
    sn = int(fits[-9:-5])
    obj = lzju.hdr(hdr, 'object').strip()
    if obj == '' : obj = 'NONE'
    obj = obj.replace("'", '')
    fil = lzju.hdr(hdr, 'filter', 'NONE').strip()
    ext = lzju.tryfloat(lzju.hdr(hdr, 'exptime', '0.0'))
    ra  = lzju.sex2dec(lzju.hdr(hdr, 'ra', '00:00:00')) * 15.0
    dec = lzju.sex2dec(lzju.hdr(hdr, 'dec', '00:00:00'))
    fid = '%4.4dB%4.4d'%(mjd, sn)
    sql = "INSERT INTO ObsFileBasic (FileID, Telescope, MJD, ObsTime, SN, ObjType, Object, Filter, ExpTime, RADeg, DecDeg, Tag, FileName, Note) " + \
          "VALUES ('%s', 'B', %d, %d, %d, '%s', '%s', '%s', %f, %f, %f, 0, '%s', '')" % \
          (fid, mjd, tim, sn, objtype, obj, fil, ext, ra, dec, fits)
    #print sql
    try :
        cur.execute(sql)
    except:
        print sql
        exit()

db = MySQLdb.connect('localhost', 'uvbys', 'uvbySurvey', 'survey')
cur = db.cursor()

# handle bias, from other band
basepath = '/data/raw/bok/'

for fil in ['o', 'u', 'v'] :

    filpath = basepath+fil+'/'
    runs = [filpath+p+'/' for p in os.listdir(filpath) if os.path.isdir(filpath+p)]
    for run in runs :

        days = [p for p in os.listdir(run) if p[0] == 'J' and os.path.isdir(run+p)]
    
        for day in days :

            #yr = int(day[0:4]); mn = int(day[4:6]); dy = int(day[6:8])
            #mjd = (time.mktime((yr, mn, dy, 12, 0, 0, 0, 0, 0)) - time0) / 60 / 60 / 24
            mjd = int(day[-4:])
            #print 'J%4.4d : %s' % (mjd, day)
            dayp = run+day+'/'

            typlis = ['bias', 'flat', 'good', 'other']
            if fil != 'o' : typlis = typlis[1:4]
            for typ in typlis :

                pp = dayp+typ+'/'
                if os.path.exists(pp) :
                    ff = [pp+f for f in os.listdir(pp) if f[0] == 'd' and os.path.isfile(pp+f)]
                    for f in ff :
                        insbok(mjd, typ.upper(), f, cur)
                    db.commit()


db.close()
print 'DONE'
