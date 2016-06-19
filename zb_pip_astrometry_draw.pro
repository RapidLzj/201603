;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw result image and output text catalog
; xx.grid.eps
; xx.resid.eps
; xx.resid.sav xx.resid.txt
; xx.wcsresult.txt xx.wcsresult.sav

old_device = !d.name
set_plot, 'ps'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; grid point for astrometry result
gx = fltarr(42,42) & gy = gx
for ii= 0,20 do gx[ii,*]=(ii-20)*200 - 59
for ii=21,41 do gx[ii,*]=(ii-21)*200 + 60
for ii= 0,20 do gy[*,ii]=(ii-20)*200 - 182
for ii=21,41 do gy[*,ii]=(ii-21)*200 + 182
zh_xy2ad, gx, gy, result, rag, decg
; x/y cross
xcrossx = (5 - findgen(11)) * 100 & xcrossy = fltarr(11)
ycrossy = xcrossx & ycrossx = xcrossy
zh_xy2ad, xcrossx, xcrossy, result, xcrossra, xcrossdec
zh_xy2ad, ycrossx, ycrossy, result, ycrossra, ycrossdec

device,filename=sci_path + file + '.grid.eps',$
  /color,bits_per_pixel=16,xsize=20,ysize=20, $
  /encapsulated,yoffset=0,xoffset=0,/TT_FONT,/helvetica,/bold,font_size=12
loadct, 39
plotsym, 0, 1
plot, rag, decg, xr=[min(rag),max(rag)], yr=[min(decg),max(decg)], psym=7, symsize=0.1, $
  pos=[0.05,0.05,0.95,0.95], xs=1, ys=1 ;,color='000000'xl, back='ffffff'xl
maxc = max(magc[cid]) & maxs = max(mags[sid])
; draw stars
for ii=0, nmatch-1 do oplot, [rac[cid[ii]]], [decc[cid[ii]]], psym=1, symsize=maxc-magc[cid[ii]], color=28;'0000ff'xl
for ii=0, nmatch-1 do oplot, [rasout[ii]], [decsout[ii]], psym=8, symsize=maxs-mags[sid[ii]], color=240;'ff0000'xl
; draw x/y cross
oplot, xcrossra, xcrossdec, line=1, color=100
oplot, ycrossra, ycrossdec, line=1, color=100
xyouts, xcrossra[0], xcrossdec[0], 'X', color=100
xyouts, ycrossra[0], ycrossdec[0], 'Y', color=100

device, /close

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; plot jpg of original image, not doing now

;meanclip, dat, med, std
;im = bytscl(alog10(dat), min=alog10(med+2*std),  max=alog10(med+25*std))
;mmm = !p.multi
;!p.multi = [4, 2, 2]
;window, 0, xs=1000, ys=1000
;imdisp, im, /axis, /data, pos=[0.03, 0.03, 0.87, 0.87]
;oplot, xs[sid], ys[sid], color='000090'XL, psym=8, symsize=2
;; mark scat results in yellow cross
;;for ii = 0, n_cata-1 do $
;for ii = 0, nmatch-1 do $
;  oplot, [xc[ii]], [yc[ii]], color='00FFFF'XL, $
;  psym=1, thick=1, symsize=( (14-magc[cid[ii]])/2 )<4>1
;;oplot, [xc[cid[ii]]], [yc[cid[ii]]], color='00FFFF'XL, $
;;  psym=1, thick=1, symsize=( (14-magc[cid[ii]])/2 )<4>1
;;  if magc[ii] lt 12.0 then oplot, [xc[ii]], [yc[ii]], color='00FFFF'XL, $
;;    psym=2, thick=1, symsize=( (14-magc[ii])/2 )<4>1
;;for ii = 0, n_bstar-1 do $
;;  oplot, [xs[ii]], [ys[ii]], color='FF00FF'XL, $
;;    psym=4
;;oplot, xs[sid], ys[sid], color='00FFFF', psym=1, symsize=3
;for ii=0,nmatch-1 do oplot, $
;  [xc[ii], xs[sid[ii]]], [yc[ii], ys[sid[ii]]], thick=1
;
;plot, crxs[sid], resid_ra , psym=3, xr=[-2000,2000], pos=[0.05, 0.85, 0.85, 0.95]
;plot, resid_dec, crys[sid], psym=3, yr=[-2000,2000], pos=[0.85, 0.05, 0.95, 0.85]
;plot, sqrt(crxs[sid]^2+crys[sid]^2), resid_dis, psym=3, pos=[0.85, 0.85, 0.95, 0.95]
;
;write_jpeg, chk_jpg, tvrd(true=1), true=1, quality=100
;!p.multi=mmm

; output residual data
rxs = xs[sid] & rys = ys[sid] & rcrxs = crxs[sid] & rcrys = crys[sid]
rras = rasout[0:*] & rdecs = decsout[0:*]
rrac = rac[cid] & rdecc = decc[cid] & rmagc = magc[cid]
;old_device = !d.name
;set_plot, 'ps'
;loadct, 39

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; output residual eps file, resid VS mag,x/y, hist
device,filename=sci_path + file + '.resid.eps',$
  /color,bits_per_pixel=16,xsize=24,ysize=16, $
  /encapsulated,yoffset=0,xoffset=0,/TT_FONT,/helvetica,/bold,font_size=12
!p.MULTI = [7,4,2]
; plot resid ra/dec VS mag, rasid ra/dec VS x/y, resid x VS resid y
plot, magc[cid], resid_ra, psym=2, symsize=0.1, $
  ytitle='Resid RA (arcsec)', yr=[-2,2], $ ;title='Resid RA/Dec VS V',
  pos=[0.05, 0.75, 0.55, 0.95]
oplot, [10,25], [0,0]+med_resid_ra+sig_resid_ra, line=1
oplot, [10,25], [0,0]+med_resid_ra-sig_resid_ra, line=1
oplot, [10,25], [0,0]+med_resid_ra, line=2

plot, magc[cid], resid_dec, psym=2, symsize=0.1, $
  xtitle='B (mag)', ytitle='Resid Dec (arcsec)', yr=[-2,2], $ ;title='Resid RA/Dec VS V',
  pos=[0.05, 0.55, 0.55, 0.75]
oplot, [10,25], [0,0]+med_resid_dec+sig_resid_dec, line=1
oplot, [10,25], [0,0]+med_resid_dec-sig_resid_dec, line=1
oplot, [10,25], [0,0]+med_resid_dec, line=2

plot, crxs[sid], resid_ra, psym=2, symsize=0.1, xrange=[-4000,4000], $
  xtitle='X to center (pixel)', ytitle='Resid RA (arcsec)', yr=[-2,2], $ ;title='Resid RA VS X',
  pos=[0.05, 0.30, 0.55, 0.50]
oplot, [-4000,4000], [0,0]+med_resid_ra+sig_resid_ra, line=1
oplot, [-4000,4000], [0,0]+med_resid_ra-sig_resid_ra, line=1
oplot, [-4000,4000], [0,0]+med_resid_ra, line=2

plot, crys[sid], resid_dec, psym=2, symsize=0.1, xrange=[-4000,4000], $
  xtitle='Y to center (pixel)', ytitle='Resid Dec (arcsec)', yr=[-2,2], $ ;title='Resid Dec VS Y',
  pos=[0.05, 0.05, 0.55, 0.25]
oplot, [-4000,4000], [0,0]+med_resid_dec+sig_resid_dec, line=1
oplot, [-4000,4000], [0,0]+med_resid_dec-sig_resid_dec, line=1
oplot, [-4000,4000], [0,0]+med_resid_dec, line=2

plot, resid_ra, resid_dec, psym=2, symsize=0.1, xr=[-2,2], yr=[-2,2], $
  xtitle='Redis RA (arcsec)', ytitle='Resid Dec (arcsec)', $ ;title='Resid RA VS Resid Dec',
  pos=[0.61, 0.45, 0.95, 0.95]
oplot, sig_resid_dis*cos(findgen(64)*0.1), sig_resid_dis*sin(findgen(64)*0.1), line=1

plothist, resid_ra, bin=0.05, xtitle='Resid RA (arcsec)', $ ; title='Histogram of Resid RA (arcsec)', $
  pos=[0.61, 0.05, 0.76, 0.40], xr=[-2,2], yr=[0,50]
oplot, [0,0]+med_resid_ra-sig_resid_ra, [0,50], line=1
oplot, [0,0]+med_resid_ra+sig_resid_ra, [0,50], line=1
oplot, [0,0]+med_resid_ra, [0,50], line=2
plothist, resid_dec, bin=0.05, xtitle='Resid Dec (arcsec)', $ ; title='Histogram of Resid Dec (arcsec)', $
  pos=[0.80, 0.05, 0.95, 0.40], xr=[-2,2], yr=[0,50]
oplot, [0,0]+med_resid_dec-sig_resid_dec, [0,50], line=1
oplot, [0,0]+med_resid_dec+sig_resid_dec, [0,50], line=1
oplot, [0,0]+med_resid_dec, [0,50], line=2
device, /close  ; xx.resid.eps
!p.multi = [0]

;;when wcs is ok, use mag_corr, else use auto. if magcorr is ok, mag_corr will be covered
;if wcsmag_const lt 90 then mags = stars.mag_corr else mags = stars.mag_auto
;; update msk with wcsmag_const or mag_const
;if mag_const lt 90 then msk += mag_const else if wcsmag_const lt 90 then msk += wcsmag_const

; plot mag--err eps
;device,filename=sci_path + file + '.magerr.eps', $
;  /color,bits_per_pixel=16,xsize=16,ysize=16, $
;  /encapsulated,yoffset=0,xoffset=0,/tt_font,/helvetica,/bold,font_size=8
;!p.multi = [0,0,0]
;plot, mags, mage, psym=3, xrange=[8,24], yrange=[0.0001,1], /ylog, $
;  xtitle='V (mag)', ytitle='mag_err (mag)', xs=1, ys=1
;; plot grid
;;for k = 0,4 do oplot, msk[k] + [-1,+1], mef[k,*], color=100, thick=2
;for k = 0,4 do oplot, magfit[k,*], errfit[k,*], color=100, thick=2
;; oplot, msf, mef4, color=100, thick=2
;for k=0,4 do oplot, [8,25], mek[[k,k]], linestyle=2
;for k=0,4 do oplot, msk[[k,k]], [0.0001, 1], linestyle=2;, color=colors[g]
;for k=0,4 do xyouts, msk[k], mek[k]*0.6, string(msk[k], format='(F5.2)')

;device, /close
set_plot, old_device

;openw, lun_out, sci_path + file + '.magerr.txt'
;printf, lun_out, '# File', 'M'+['5','10','50','100','1000'], 'fwhm', 'sigma', 'elong', 'sigma', $
;  format='(A-10, 5(2X,A5), 4(2X,A5))'
;printf, lun_out, file, msk, med_fwhm, sig_fwhm, med_elong, sig_elong, $
;  format='(A10, 5(2X,F5.2), 4(2X,F5.2))'
;close, lun_out

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw finish, begin text and save file

save, filename=sci_path + file + '.resid.sav', $
  rxs, rys, rcrxs, rcrys, rrac, rdecc, rmagc, rras, rdecs, resid_ra, resid_dec, resid_dis
openw, lun_out, sci_path + file + '.resid.txt', /get_lun
printf, lun_out, '#', 'X','Y','CT-X', 'CT-Y', 'RA-CATA', 'DEC-CATA', 'RA-STAR', 'DEC-STAR', 'RA-ERR', 'DEC-ERR', 'DIS-ERR', 'MAG', $
  format='(1A,4A12,7A13,A7)'
;for i = 0, nmatch-1 do begin
;  printf, lun_out, xs[sid[i]], ys[sid[i]], crxs[sid[i]], crys[sid[i]], $
;    rac[cid[i]], decc[cid[i]], rasout[i], decsout[i], $
;    resid_ra[i], resid_dec[i], resid_dis[i], magc[cid[i]], format='(4D12.5,7D13.8,F7.2)'
;endfor
r_writecol, lun_out, xs[sid], ys[sid], crxs[sid], crys[sid], $
  rac[cid], decc[cid], rasout, decsout, $
  resid_ra, resid_dec, resid_dis, magc[cid], $
  fmt=[replicate('D12.5',4),replicate('D13.8',7),'F7.2']
close, lun_out
free_lun, lun_out

; output result data
save, result, filename=sci_path + file + '.wcsresult.sav'
openw, lun_out, sci_path + file + '.wcsresult.txt', /get_lun
printf, lun_out, result.level, result.n_item, format='(I1,2X,I2)'
printf, lun_out, result.aconst, format='(D16.12,"   0.0")'
for i = 0, result.n_item-1 do   printf, lun_out, result.a[i], result.asigma[i], format='(E18.11,2X,E18.11)'
printf, lun_out, result.bconst, format='(D16.12,"   0.0")'
for i = 0, result.n_item-1 do   printf, lun_out, result.b[i], result.bsigma[i], format='(E18.11,2X,E18.11)'
close, lun_out
free_lun, lun_out

