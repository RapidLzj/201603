import MySQLdb

db = MySQLdb.connect('localhost', 'lzj', 'mima1977', 'survey')
cur=db.cursor() 
cur.execute('select * from ObsRun')

r = cur.fetchall()

for rr in r: 
  for d in range(rr[1],rr[2]+1) :
    sql = "INSERT INTO ObsNight (NightID, MJD, RunID) VALUES('%4d%1s', %4d, '%s')"%(d, rr[3][0], d,rr[0])
    print sql
    cur.execute(sql)

db.submit()

db.close()

