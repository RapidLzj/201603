;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Flags for result of pipeline section
FLAG_OK     = -1   ; success finished normal, seldom use
FLAG_SKIP   = -2  ; skipped by keywords, or prior step fails
FLAG_FAIL   = -3  ; fail, too few stars, or wcs match fail, or big residual, or no flux std
FLAG_ERROR  = -4  ; Error found, missing files, unbalanced match
; use positive numbers for found or matched stars, also success
