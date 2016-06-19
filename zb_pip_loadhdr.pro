;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; image header load

hdr = headfits(obs_fits)
ob = strtrim(sxpar(hdr, 'OBJECT'), 2)
fn = file ; strmid(sxpar(hdr, 'FILENAME'), 0, 10)
fs = strmid(fn, 3, 4, /reverse) ; strmid(sxpar(hdr, 'FILENAME'), 6, 4)
fi = strtrim(sxpar(hdr, 'FILTER'), 2)
ut = strtrim(sxpar(hdr, 'UT'), 2)
jd = fix(sxpar(hdr, 'JULIAN') - 2450000.5)
et = sxpar(hdr, 'EXPTIME') * 1.0d

if strmid(ob,0,1) eq "'" then ob = strmid(ob, 1, strlen(ob)-1)
if strmid(ob,0,1,/reverse) eq "'" then ob = strmid(ob,0,strlen(ob)-1)

if ob eq '' then ob = 'unknown'
if ~ strnumber(fs) then fs = -1


fov = 1.0d ; field of view 1.0 deg
pix_scale = 0.445d / 3600.0d ;in degrees.*3600.d0 ; arcsec
rot_ang = 0.0

; fix hdr1 for datatype
sxaddpar, hdr, 'BZERO',  0.0
