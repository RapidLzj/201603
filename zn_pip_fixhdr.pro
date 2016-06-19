;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; image header load and fix

hdr = headfits(obs_fits)
ob = strtrim(sxpar(hdr, 'OBJECT'), 2)
fn = file ; strmid(sxpar(hdr, 'FILENAME'), 0, 10)
fs = sxpar(hdr, 'OBSNUM') ;strmid(fn, 3, 4, /reverse) ; strmid(sxpar(hdr, 'FILENAME'), 6, 4)
fi = strtrim(sxpar(hdr, 'FILTER'), 2)
ut = strtrim(sxpar(hdr, 'DATE-OBS'), 2)
;jd = fix(sxpar(hdr, 'JULIAN') - 2450000.5)
et = sxpar(hdr, 'EXPTIME') * 1.0d

if strmid(ob,0,1) eq "'" then ob = strmid(ob, 1, strlen(ob)-1)
if strmid(ob,0,1,/reverse) eq "'" then ob = strmid(ob,0,strlen(ob)-1)

if ob eq '' then ob = 'unknown'
if ~ strnumber(fs) then fs = -1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fix image header

; Observation Date and Time
sxaddpar, hdr, 'DATE-OBS', strmid(ut, 0, 10)
sxaddpar, hdr, 'TIME-OBS', strmid(ut, 11, 12)

; wcs info
; correct object ra/dec (read OBJCTRA OBJCTDEC) (write RA DEC OBJCTRA OBJCTDEC CRVAL1 CRVAL2)
ctra  = sxpar(hdr, 'OBJCTRA') * 15.0
ctdec = sxpar(hdr, 'OBJCTDEC') * 1.0
ctx = nx - 0.5 & cty = ny - 0.5

sxaddpar, hdr, 'RA'      , dec2hms(ctra / 15.0), 'RA of Object (hms)'
sxaddpar, hdr, 'DEC'     , dec2hms(ctdec), 'Dec of Object (dms)'
sxaddpar, hdr, 'OBJCTRA' , ctra , 'RA of Object (degree)'
sxaddpar, hdr, 'OBJCTDEC', ctdec, 'Dec of Object (degree)'
sxaddpar, hdr, 'CRVAL1'  , ctra
sxaddpar, hdr, 'CRVAL2'  , ctdec
; keep old ra/dec
sxaddpar, hdr, 'OLD-RA'   , dec2hms(ctra / 15.0), 'Original RA of Object (hms)'
sxaddpar, hdr, 'OLD-DEC'  , dec2hms(ctdec), 'Original Dec of Object (dms)'
sxaddpar, hdr, 'OLD-CTRA' , ctra , 'Original RA of Object (degree)'
sxaddpar, hdr, 'OLD-CTDE', ctdec, 'Original Dec of Object (degree)'
sxaddpar, hdr, 'OLD-CRV1', ctra,  'Old Reference Value 1 (RA)'
sxaddpar, hdr, 'OLD-CRV2', ctdec, 'Old Reference Value 2 (Dec)'
; center of image ( object x/y)
sxaddpar, hdr, 'XCNTPIX' , ctx
sxaddpar, hdr, 'YCNTPIX' , cty
sxaddpar, hdr, 'OBJCTX'  , ctx
sxaddpar, hdr, 'OBJCTY'  , cty
sxaddpar, hdr, 'CRPIX1'  , ctx
sxaddpar, hdr, 'CRPIX2'  , cty

; other info
sxaddpar, hdr, 'EQUINOX' , 2000.0
sxaddpar, hdr, 'EPOCH'   , 2000.0
sxaddpar, hdr, 'RADECSYS', 'FK5'
sxaddpar, hdr, 'WCSDIM'  , 2
sxaddpar, hdr, 'CTYPE1'  , 'RA---TAN'
sxaddpar, hdr, 'CTYPE2'  , 'DEC--TAN'
sxaddpar, hdr, 'EPOCH'   , 2000.0
sxaddpar, hdr, 'CUNIT1'  , 'deg'
sxaddpar, hdr, 'CUNIT2'  , 'deg'

fov = 1.3d ; field of view 1.3 deg
pix_scale = 1.13d/3600.0d ;1.0*fov/ss[0] ; in degrees.*3600.d0 ; arcsec
rot_ang = 0.0

sxaddpar, hdr, 'CROTA1'  , rot_ang
sxaddpar, hdr, 'CROTA2'  , rot_ang
pix_scale2 = pix_scale / cos(ctdec/180.0*!pi)
cd1_1 = -pix_scale2 * cos(rot_ang/180.0*!pi) & cd1_2 = -pix_scale2 * sin(rot_ang/180.0*!pi)
cd2_2 =  pix_scale  * cos(rot_ang/180.0*!pi) & cd2_1 = -pix_scale  * sin(rot_ang/180.0*!pi)
sxaddpar, hdr, 'CD1_1', cd1_1
sxaddpar, hdr, 'CD1_2', cd1_2
sxaddpar, hdr, 'CD2_1', cd2_1
sxaddpar, hdr, 'CD2_2', cd2_2

; site info and observation date and time, from header
site_ele = sxpar(hdr, 'SITEELEV') * 1.0
;site_lat = hms2dec(sxpar(hdr, 'SITELAT' ))
;site_lon = hms2dec(sxpar(hdr, 'SITELONG')) * (-1.0)
site_lat = sxpar(hdr, 'SITELAT' )
site_lon = sxpar(hdr, 'SITELONG')
date_obs = strmid(ut, 0, 10)
time_obs = strmid(ut, 11, 11)
objra    = ctra
objdec   = ctdec
;if verbose then print, date_obs, format='("Observation date: ",A)'
jd = julday(strmid(date_obs, 5,2), strmid(date_obs, 8,2), strmid(date_obs, 0,4), $
            strmid(time_obs,0,2), strmid(time_obs,3,2), strmid(time_obs,6,5))
; calc moon phase/ra/dec, transfer to moon azimuth/altitud (MPHASE RA_MOON DEC_MOON MAZIMUTH MALTITUD)
moonpos, jd, mra, mdec
mphase, jd, mph
eq2hor, mra, mdec, jd, malt, maz, mha, lat=site_alt, lon=site_lon, alt=site_ele
sxaddpar, hdr, 'MPHASE'  , mph*100.0,  'Moon phase, percent'
sxaddpar, hdr, 'RA_MOON' , mra,  'RA of Moon (degree)'
sxaddpar, hdr, 'DEC_MOON', mdec, 'Dec of Moon (degree)'
sxaddpar, hdr, 'MAZIMUTH', maz,  'Azimuth of Moon (degree)'
sxaddpar, hdr, 'MALTITUD', malt, 'Altitude of Moon (degree)'
; calc moon-object angle (MANGLE)
ma = map_2points(mra, mdec, objra, objdec)
ma = ma[0]
sxaddpar, hdr, 'MANGLE'  , ma, 'Angle from Moon to Object (degree)'
; object Alt and Az, HA (write AZMTHANG ELEANG HA AIRMASS)
eq2hor, objra, objdec, jd, objalt, objaz, objha, lat=site_alt, lon=site_lon, alt=site_ele
airmass = 1.0 / sin(( objalt + 244.0 /(165.0 + 47.0 * objalt ^ 1.1) ) * !pi / 180.d)
sxaddpar, hdr, 'AZIMUTH', objaz
sxaddpar, hdr, 'ELEVAT', objalt
sxaddpar, hdr, 'HA', objha
sxaddpar, hdr, 'AIRMASS', airmass

; fix hdr1 for datatype
sxaddpar, hdr, 'BZERO',  0.0
