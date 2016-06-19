; this section analysis mag depth and draw mag-err graph

old_device = !d.name
set_plot, 'ps'
loadct, 39

if final_step ge 3 then begin
    mm = 'Calibrated mag'
    cc = mag_const
endif else if final_step eq 2 then begin
    mm = 'Estimated mag'
    cc = wcsmag_const
endif else begin
    mm = 'Instrumental mag'
    cc = 0.0
endelse

device,filename=sci_path + file + '.magerr.eps',$
  /color,bits_per_pixel=16,xsize=20,ysize=12, $
  /encapsulated,yoffset=0,xoffset=0,/TT_FONT,/helvetica,/bold,font_size=12
plotsym, 0, 1

; plot stars
plot, stars.mag_auto + cc, stars.magerr_auto, xr=[8,22], yr=[0, 0.25], psym=7, symsize=0.1, $
    pos=[0.05,0.05,0.95,0.95], xs=1, ys=1, $
    xtitle=mm, ytitle='Error', title=file
; plot maglimit
lm = limitmagx + cc
for i = 0, nlimit-1 do begin
    oplot, lm[i]+[-1,1], limiterrx[i]+[0,0], line=2
    oplot, lm[i]+[0,0], [0,limiterrx[i]+0.01], line=2
    xyouts, lm[i]-1.0, limiterrx[i]+[0,0]+0.005, string(lm[i], format='(F5.2)')
endfor
; plot check err
for i = 0, ncheck-1 do begin
    oplot, checkmagx[i]+[-1,1], checkerrx[i]+[0,0], line=1
endfor

device, /close

set_plot, old_device
