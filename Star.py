import os
import pyfits
import MySQLdb
#import time
import lzjutil as lzju

def insstar (cur, fileid, filepath, laststep) :
    sql0 = "INSERT INTO Stars(StarCode    ,FileID      ,Version     ,NoInFile    ," + \
        "AmpNo       ,ImgX        ,ImgY        ,Elong       ,Fwhm        ," + \
        "MagAuto     ,MagAutoErr  ,MagAper     ,MagAperErr  ,MagPetro    ,MagPetroErr ," + \
        "Background  ,Flags       ," + \
        "MagCorr     ,MagCorrErr  ," + \
        "RADeg       ,DecDeg      ,RAErr       ,DecErr      ," + \
        "Tag         ,IxWcs       ,IxMag       ,IxCross     ,Note        ) " + \
        "VALUES ('%s#%5.5d', '%s', 1, %d, " + \
        "%d, %f, %f, %f, %f, " + \
        "%f, %f, %f, %f, %f, %f, " + \
        "%f, %d, " + \
        "%f, %f, " + \
        "%f, %f, %f, %f, " + \
        "%d, %d, %d, %d, '')"
    steps = ['', '', 'wcs', 'wcs', 'mag']
    basename = filepath.split('/')[-2]
    ldac = filepath + basename + '.' + steps[laststep] + '.ldac'
    cntfile = 0

    hdu = pyfits.open(ldac)
    stars = hdu[1].data
    for star in stars :
        cntfile += 1
        sql = sql0 % (fileid, star['SN'], fileid, star['SN'],
            star['AMP'], star['X'], star['Y'], star['ELONG'], star['FWHM'],
            star['MAG_AUTO'], star['MAGERR_AUTO'],
            star['MAG_APER'], star['MAGERR_APER'],
            star['MAG_PETRO'], star['MAGERR_PETRO'],
            0.0, star['FLAGS'],
            star['MAG_CORR'], star['MAGERR_CORR'],
            star['RADEG'], star['DECDEG'], star['RAERR'], star['DECERR'],
            laststep, star['IXWCS'], star['IXMAG'], star['IXCROSS'])
        cur.execute(sql)
        #print sql
    return (cntfile)

# Main program

if __name__ == '__main__' :

    db = MySQLdb.connect('localhost', 'uvbys', 'uvbySurvey', 'survey')
    cur = db.cursor()

    cur.execute("SELECT FileID, FilePath, LastStep FROM FileReduceResult " + \
        "WHERE LastStep >= 2")
    tb = cur.fetchall()

    cntall = 0
    for row in tb :
        cntfile = insstar(cur, row[0], row[1], row[2])
        cntall += cntfile
        #if cntall >= 10 : exit()
        db.commit()
    db.close()
    print cntall, ' DONE'
