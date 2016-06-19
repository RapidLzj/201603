y = 0 & m = 0 & d = 0 & r = '' & t = 0 & f = 0
read, y, m, d, r
r = strtrim(r,2)
;t = (['','good','other','bad'])[t]
;f = (['','u','v','b','y','Hw','Hn'])[f]
print, y, m, d, r, t, f, format='("Date :",I4.4,"-",I2.2,"-",I2.2,"  Run:",A8,"  Type:",A6,"  Filter:",A3)'
obj_xao, y, m, d, r;, t, f
exit
