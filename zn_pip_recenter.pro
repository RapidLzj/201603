    openw, lun_out, sci_path + file + '.recenter.txt', /get_lun

    ; sort catalog stars by mag, and keep brightest
    ixr = sort(magc)
    ixr = ixr[0:(100<n_cata)-1]
    rarc = rac[ixr] & decrc = decc[ixr] & magrc = magc[ixr]

    ; sort image stars by mag, keep brightest
    ixr = sort(mags)
    ixr = ixr[0:(30<n_bstar)-1]
    xrs = xs[ixr] & yrs = ys[ixr] & magrs = mags[ixr]

    ;window, xs=1000,ys=800
    ;plothist, magrc, bin=0.1, xr=[10,15], color=0
    ;plothist, magrs+4, bin=0.1, color='ff0000'xl, /over
    ;stop
    ad2xy, rarc, decrc, ast_ini, xrc, yrc
    ;plot, xrc, yrc, psym=1
    ;oplot, xrs, yrs, psym=6, color='00ffff'xl
    ;stop

    ; begin try
    ; for bok (not decided)
    ;try_count = [   5,     5,    5,    5,   5   ]
    ;val_step  = [1296.0, 216.0, 36.0,  6.0, 1.0 ] / 3600.0
    ;check_sig = [2500.0, 400.0, 60.0, 15.0, 4.0 ]

    ; for nowt
    try_count = [  4,    4,    4,   4   ]
    val_step  = [125.0, 25.0,  5.0, 1.0 ] / 3600.0
    ang_step  = [  2.0,  0.5,  0.1, 0.02]
    check_sig = [100.0, 50.0, 25.0, 5.0 ]
    cr = ast_ini.crval
    rot_ang = 0.0 / 180.0 * !pi

    ; use original wcs param as initial guess
    ;extast, hdr, ast_ini
    cr = ast_ini.crval
    cr0 = cr
    rt0 = rot_ang

    if screenmode gt 0 then print, format='("Re-allocate center and rotate. ")'
    for k=0, 3 do begin
      if screenmode gt 0 then print, k+1, format='("--> Stage ",I1, " ", $)'
      try_n = try_count[k] + try_count[k] + 1
      val1check = (findgen(try_n)-try_count[k]) * val_step[k] + cr[0]
      val2check = (findgen(try_n)-try_count[k]) * val_step[k] + cr[1]
      angcheck  = (findgen(try_n)-try_count[k]) * ang_step[k] + rot_ang

      qcheck = fltarr(try_n, try_n, try_n)
      for kk = 0,try_n-1 do begin
        if screenmode gt 0 then print, format='(">",$)'
        ast_ini.cd[0,0] = -cos(angcheck[kk] / 180.0d * !dpi) * pix_scale
        ast_ini.cd[0,1] = -sin(angcheck[kk] / 180.0d * !dpi) * pix_scale
        ast_ini.cd[1,0] = -sin(angcheck[kk] / 180.0d * !dpi) * pix_scale
        ast_ini.cd[1,1] =  cos(angcheck[kk] / 180.0d * !dpi) * pix_scale
        for ii = 0,try_n-1 do begin
          ast_ini.crval[0] = val1check[ii]
          ;if screenmode gt 0 then print, format='(" >",$)'
          for jj = 0,try_n-1 do begin
            ast_ini.crval[1] = val2check[jj]
            ad2xy, rarc, decrc, ast_ini, xrc, yrc
            qcheck[ii, jj, kk] = zh_conv_xy(xrc, yrc, magrc, xrs, yrs, magrs, check_sig[k])
          endfor
        endfor
      endfor
      ;if screenmode gt 0 then print, ''
      ;for kk=0,try_n-1 do begin surface, qcheck[*,*,kk] & wait, 1 & endfor
      ;stop
      ixq = where(qcheck eq max(qcheck))
      ixq3 = array_indices(qcheck, ixq)
      ;print, cr[0], cr[1], rot_ang, 3600.0*(val1check[ixq3[0]]-cr[0]), 3600.0*(val2check[ixq3[1]]-cr[1]), angcheck[ixq3[2]]-rot_ang
      ;for kk=0,try_n-1 do begin surface,qcheck[*,*,kk],val1check,val2check, title=string(angcheck[kk], format='(F5.2)') & wait, 1 & endfor
      ;stop
      cr[0] = val1check[ixq3[0]]
      cr[1] = val2check[ixq3[1]]
      rot_ang = angcheck[ixq3[2]]
      printf, lun_out, cr, rot_ang, 3600*(cr-cr0), (rot_ang-rt0), $
        format='("New",2(2X,F8.4),(2X,F6.2), " Corr",2(2X,F7.1),(2X,F6.2))'
      if screenmode eq 2 then print, cr, rot_ang, 3600*(cr-cr0), (rot_ang-rt0), $
        format='("New",2(2X,F8.4),(2X,F6.2), " Corr",2(2X,F7.1),(2X,F6.2))' $
      else if screenmode gt 0 then print, ''
    endfor

    ast_ini.cd[0,0] = -cos(rot_ang / 180.0d * !dpi) * pix_scale
    ast_ini.cd[0,1] = -sin(rot_ang / 180.0d * !dpi) * pix_scale
    ast_ini.cd[1,0] = -sin(rot_ang / 180.0d * !dpi) * pix_scale
    ast_ini.cd[1,1] =  cos(rot_ang / 180.0d * !dpi) * pix_scale
    ast_ini.crval[0] = cr[0]
    ast_ini.crval[1] = cr[1]
    printf, lun_out, cr[0], dec2hms(cr[0]/15.0), cr[1], dec2hms(cr[1]), rot_ang, $
      dec2hms(cr0[0]/15.0), dec2hms(cr0[1]), rt0, $
      3600.0*(cr[0] - cr0[0]), 3600.0*(cr[1] - cr0[1]), (rot_ang-rt0), $
      format='("Find center:", 2(1X,F7.3,"(",A9,")"),(2X,F6.2), "  Original ", 2(1X,A9),(1X,F6.2), "  Correction ", 2(1X,F7.1),(1X,F6.2))'

    if screenmode gt 0 then print, cr[0], dec2hms(cr[0]/15.0), cr[1], dec2hms(cr[1]), rot_ang, $
      dec2hms(cr0[0]/15.0), dec2hms(cr0[1]), rt0, $
      3600.0*(cr[0] - cr0[0]), 3600.0*(cr[1] - cr0[1]), (rot_ang-rt0), $
      format='("Find center:", 2(1X,F7.3,"(",A9,")"),(2X,F6.2), "  Original ", 2(1X,A9),(1X,F6.2), "  Correction ", 2(1X,F7.1),(1X,F6.2))'

    close, lun_out & free_lun, lun_out