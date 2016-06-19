; pipeline shell

args = command_line_args(count=cnt)

tel  = args[0]
rawp = args[1]
redp = args[2]
bare = args[3]
bias = args[4]
flat = args[5]

print, tel,rawp,redp,bare,bias,flat,format='("(",a,")")'

if tel eq 'B' then $
    zb_pip, rawp, redp, bare, bias, flat, /magauto,/over,/ub1,/verbose,/keep $
else if tel eq 'N' then $
    zn_pip, rawp, redp, bare, bias, flat, /magauto,/over,/ub1,/verbose,/keep $
else $
    print, 'Unknown telescope code'

exit
