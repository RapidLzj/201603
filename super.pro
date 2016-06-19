spawn, 'ls /data/red/bok/*/pass1/*/*/ -d', ddd  
n_ddd = n_elements(ddd)                         
for k = 0, n_ddd-1 do if ~ file_test(ddd[k]+'/superflat.fits') then zb_pp_flat2, ddd[k], /super

