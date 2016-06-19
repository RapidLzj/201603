import MySQLdb
import os
import lzjutil as lu
import nowt_reduce as nowtr
import bok_reduce as bokr
import Star
import sys

db = MySQLdb.connect('localhost', 'uvbys', 'uvbySurvey', 'survey')
cur = db.cursor()

st = sys.argv[1]
si = sys.argv[2]

sql = "SELECT FileID, Telescope, Type, FilterCode, FileName, RunCode, DateStr " + \
      "FROM File0520 ORDER BY FileID LIMIT %s, %s" % (st, si)

cur.execute(sql)
fs = cur.fetchall()

telx = {'B':'/data/red/bok/', 'N':'/data/red/XAO/'}
typx = {'S':'good', 'O':'other'}
filx = {'u':'u', 'v':'v', 'b':'b', 'y':'y', 'w':'Hw', 'n':'Hn'}

for f in fs :
    (fileid, tel, typ, fil, fn, rc, ds) = (f[0], f[1], f[2], f[3], f[4], f[5], f[6])

    # call idl to reduce
    rawp = os.path.dirname(fn)
    redp = telx[tel]+filx[fil]+'/pass1/'+(rc[0:6] if rc[6] == '_' else rc[0:7])+'/'+ds+'/'+typx[typ]+ '/'
    bare = os.path.basename(fn)[:-5]

    cmd = 'idl pip_shell.pro -args %s %s %s %s' % (tel, rawp, redp, bare)
    print cmd
    os.system(cmd)
    if os.path.exists(redp+bare+'/'+bare+'.db.txt') :

        # insert reduced db file
        if tel == 'B' :
            laststep = bokr.insbokred (cur, fileid, int(fileid[0:4]), fil, fn)
        elif tel == 'N' :
            laststep = nowtr.insnowtred (cur, fileid, int(fileid[0:4]), fil, fn)
        db.commit()

        # insert reduced ldac file
        Star.insstar(cur, fileid, redp+bare+'/', laststep)
        db.commit()

db.close()
print 'DONE'

