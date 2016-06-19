pro  zh_outcat, file, catalog
    ft = size(file, /type) ; type code of file
    ty = [7, 1, 2, 12, 3, 13, 14, 15] ; valid type: 7 string, 1-15: integers
    ix = (where(ft eq ty))[0]
    if ix eq 0 then begin
        openw, lun, file, /get_lun
    endif else if ix gt 0 then begin
        lun = file
    endif else begin
        message, 'File name or lun needed', /cont
        return
    endelse

    ;star1 = { sn:0L, mjd:jd, file:fs, filter:fi, $ 0--3
    ;    x:0.0, y:0.0, elong:0.0, fwhm: 0.0, $ 4--7
    ;    mag_auto :0.0, magerr_auto :0.0, $8--9
    ;    mag_best :0.0, magerr_best :0.0, $10--11
    ;    mag_petro:0.0, magerr_petro:0.0, $12--13
    ;    mag_aper :0.0, magerr_aper :0.0, $14--15
    ;    flags: 0B, $ 16
    ;    mag_corr:0.0, magerr_corr:0.0, $ 17--18
    ;    radeg:0.0d, decdeg:0.0d, raerr:0.0d, decerr:0.0d, rastr:'', decstr:'', $19--24
    ;    ixWcs:-1L, ixMag:-1L, ixCross:-1L, amp:-1 } 25--28
    r_outcat, catalog, lun, indgen(29), $ ; all fields
        ['I5','I5', 'I4.4','A6',  'F8.3', 'F8.3', 'F8.4', 'F8.4', $
        ; SN   MJD   FILE   FILTER X       Y       ELONG   FWHM
        'F8.4', 'F8.5', $
        ;MAG     Err     AUTO BEST PETRO APER
        'F8.4', 'F8.5', $
        'F8.4', 'F8.5', $
        'F8.4', 'F8.5', $
        'B8.8', 'F8.4', 'F8.5', $
        ;FLAG    MAG_C   MAGERR_C
        'D9.5', 'D+9.5', 'D9.6', 'D9.6', 'A11', 'A11', $
        ;RA_Deg  DEC_Deg  RA_Err  DEC_Err RA_Str DEC_Str
        'I6',  'I6', 'I7',  'I2' $
        ;ixWcs  Mag   Cross  Section
        ]

    if ix eq 0 then free_lun, lun ; close and free lun

end