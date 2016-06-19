;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Flags for result of pipeline section
FLAG_OK     = -1   ; success finished normal, seldom use
FLAG_SKIP   = -2  ; skipped by keywords, or prior step fails
FLAG_FAIL   = -3  ; fail, too few stars, or wcs match fail, or big residual, or no flux std
FLAG_ERROR  = -4  ; Error found, missing files, unbalanced match
; use positive numbers for found or matched stars, also success

FLAG_TITLE = ['NONE', 'OK  ', 'SKIP', 'FAIL', 'ERRO']

case !TELESCOPE of
    'BOK': begin
        ngg = 16
        ggs = string(indgen(ngg)+1, format='(I2.2)')
        ggx = strtrim(indgen(ngg)+1, 2)
        ; x/y const of image
        gapx = 119 & gapy = 364
        nx = 2016 & ny = 2048
        nx2 = nx * 2 & ny2 = ny * 2
        cnx = nx / 2 - 0.5 & cny = ny / 2 - 0.5 ; center of each amp
        nx0 = [1,0,1,0, 3,2,3,2, 0,1,0,1, 2,3,2,3] * nx ; x/y start of each amp in whole image
        ny0 = [1,1,0,0, 1,1,0,0, 2,2,3,3, 2,2,3,3] * ny
        nx0[where(nx0 ge nx2)] += gapx
        ny0[where(ny0 ge ny2)] += gapy
        rotang = [2,7,5,0, 2,7,5,0, 0,5,7,2, 0,5,7,2]
        ; center of whole image
        ctx = 4091.04 - 1 & cty = 4277.99 - 1

        fov = 1.0d ; field of view 1.3 deg
        pix_scales = 0.445d
        pix_scale = pix_scales / 3600.0d ;in degrees.*3600.d0 ; arcsec
        pixscl2 = pix_scales^2 ; pixel area to squared arcsecond
        rot_ang = 0.0
    end
    'NOWT': begin
        ngg = 4
        ggs = string(indgen(ngg)+1, format='(I1.1)')
        ggx = strtrim(indgen(ngg)+1, 2)
        nx = 2048 & ny = 2068
        nx2 = nx * 2 & ny2 =ny * 2
        nx0 = [0,1,0,1] * nx ; x/y start of each amp in whole image
        ny0 = [0,0,1,1] * ny

        fov = 1.3d ; field of view 1.3 deg
        pix_scales = 01.13d
        pix_scale = pix_scales / 3600.0d ;1.0*fov/ss[0] ; in degrees.*3600.d0 ; arcsec
        rot_ang = 0.0
        pixscl2 = pix_scales^2 ; pixel area to squared arcsecond
    end
    else: begin
        ngg = 0
        ggs = ['']
        ggx = ['']
    end
endcase
