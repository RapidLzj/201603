;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; image header load and fix

hdr = headfits(obs_fits)
ob = strtrim(sxpar(hdr, 'OBJECT'), 2)
fn = file ; strmid(sxpar(hdr, 'FILENAME'), 0, 10)
fs = strmid(fn, 3, 4, /reverse) ; strmid(sxpar(hdr, 'FILENAME'), 6, 4)
fi = strtrim(sxpar(hdr, 'FILTER'), 2)
ut = strtrim(sxpar(hdr, 'UT'), 2)
;jd = fix(sxpar(hdr, 'JULIAN') - 2450000.5)
et = sxpar(hdr, 'EXPTIME') * 1.0d

if strmid(ob,0,1) eq "'" then ob = strmid(ob, 1, strlen(ob)-1)
if strmid(ob,0,1,/reverse) eq "'" then ob = strmid(ob,0,strlen(ob)-1)

if ob eq '' then ob = 'unknown'
if ~ strnumber(fs) then fs = -1

; copy wcs init into from extesion 4 header
hdr1 = headfits(obs_fits, ext=4, /silent)

; wcs info
sxaddpar, hdr, 'EQUINOX' , sxpar(hdr1, 'EQUINOX')
sxaddpar, hdr, 'WCSDIM'  , sxpar(hdr1, 'WCSDIM')
sxaddpar, hdr, 'CTYPE1'  , sxpar(hdr1, 'CTYPE1')
sxaddpar, hdr, 'CTYPE2'  , sxpar(hdr1, 'CTYPE2')
sxaddpar, hdr, 'CRVAL1'  , sxpar(hdr1, 'CRVAL1')
sxaddpar, hdr, 'CRVAL2'  , sxpar(hdr1, 'CRVAL2')
sxaddpar, hdr, 'CRPIX1'  , sxpar(hdr1, 'CRPIX1')
sxaddpar, hdr, 'CRPIX2'  , sxpar(hdr1, 'CRPIX2')
sxaddpar, hdr, 'CD1_1'   , sxpar(hdr1, 'CD1_1')
sxaddpar, hdr, 'CD1_2'   , sxpar(hdr1, 'CD1_2')
sxaddpar, hdr, 'CD2_1'   , sxpar(hdr1, 'CD2_1')
sxaddpar, hdr, 'CD2_2'   , sxpar(hdr1, 'CD2_2')
; other info
sxaddpar, hdr, 'EPOCH'   , 2000.0
sxaddpar, hdr, 'RADECSYS', 'FK5'
sxaddpar, hdr, 'CROTA1'  , 0.0
sxaddpar, hdr, 'CROTA2'  , 0.0
sxaddpar, hdr, 'CUNIT1'  , 'deg'
sxaddpar, hdr, 'CUNIT2'  , 'deg'

; keep old ra/dec
sxaddpar, hdr, 'OLD-RA' , sxpar(hdr, 'RA') ,    'Old Right Ascension'
sxaddpar, hdr, 'OLD-DEC', sxpar(hdr, 'DEC'),    'Old Declination'
sxaddpar, hdr, 'OLD-CRV1', sxpar(hdr, 'CRVAL1'), 'Old Reference Value 1 (Dec)'
sxaddpar, hdr, 'OLD-CRV2', sxpar(hdr, 'CRVAL2'), 'Old Reference Value 2 (RA)'

; site info and observation date and time, from header
site_ele = sxpar(hdr, 'SITEELEV') * 1.0
site_lat = hms2dec(sxpar(hdr, 'SITELAT' ))
site_lon = hms2dec(sxpar(hdr, 'SITELONG')) * (-1.0)
date_obs = sxpar(hdr, 'DATE-OBS')
time_obs = sxpar(hdr, 'TIME-OBS')
objra    = sxpar(hdr, 'CRVAL2')
objdec   = sxpar(hdr, 'CRVAL1')
;if verbose then print, date_obs, format='("Observation date: ",A)'
jd = julday(strmid(date_obs, 5,2), strmid(date_obs, 8,2), strmid(date_obs, 0,4), $
            strmid(time_obs,0,2), strmid(time_obs,3,2), strmid(time_obs,6,6))
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

fov = 1.0d ; field of view 1.3 deg
pix_scale = 0.445d / 3600.0d ;in degrees.*3600.d0 ; arcsec
rot_ang = 0.0

; fix hdr1 for datatype
sxaddpar, hdr, 'BZERO',  0.0
