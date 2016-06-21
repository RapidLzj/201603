"""
    match two list of stars, provided by ra/dec degree
"""

import numpy as np


def star_match ( list_a, list_b, a_ra, a_dec, b_ra, b_dec, a_mag=-1, b_mag=-1,
                 dis_limit=0.002, mag_limit=-3 ) :
    """match two list
    :param list_a: list a of stars, each item is a star, stars as list with property
    :param list_b: list b of stars
    :param a_ra: ra field index in list a
    :param a_dec: dec field index in list a
    :param b_ra: ra field index in list b
    :param b_dec: dec field index in list b
    :param a_mag: mag field index in list a, -1 means no mag, default is -1
    :param b_mag: mag field index in list a, -1 means no mag, default is -1
    :param dis_limit: distance limit when matching, default is 0.002 deg, 7.2 arcsec
    :param mag_limit: mag difference when checking, 0 means no check,
        minus means times of sigma, positive is mag difference, default is -3
    :returns: 3 items tuple, index of a, index of b, and matching count
    """

    len_a = len(list_a)
    len_b = len(list_b)

    ra_a = np.array([k[a_ra] for k in list_a])
    dec_a = np.array([k[a_dec] for k in list_a])
    ra_b = np.array([k[b_ra] for k in list_b])
    dec_b = np.array([k[b_dec] for k in list_b])
    if a_mag >= 0 :
        mag_a = np.array([k[a_mag] for k in list_a])
    else :
        mag_a = np.zeros(len_a)
    if b_mag >= 0 :
        mag_b = np.array([k[b_mag] for k in list_b])
    else :
        mag_b = np.zeros(len_b)

    ra_scale = np.cos(np.median(dec_a) / 180.0 * np.pi)

    ix_a = np.argsort(dec_a)
    ix_b = np.argsort(dec_b)

    out_a , out_b = [] , []
    pbf = pbt = 0  # point b from/to
    for pa in range(len_a) :
        ix_pa = ix_a[pa]
        ra_p, dec_p = ra_a[ix_pa], dec_a[ix_pa]
        # pb walk down to first position [pbf]>=[pa]-dis, [pbt]>=[pa]+dis
        while pbf < len_b and dec_b[ix_b[pbf]] < dec_p - dis_limit : pbf += 1
        while pbt < len_b and dec_b[ix_b[pbt]] < dec_p + dis_limit : pbt += 1
        # exit if p2f runout
        if pbf >= len_b : break
        # skip if no near star
        if pbt - pbf < 1 : continue
        # check real distance, include ra
        for ix_pb in ix_b[range(pbf, pbt)] :
            dis = np.sqrt(((ra_p - ra_b[ix_pb]) * ra_scale) ** 2 + (dec_p - dec_b[ix_pb]) ** 2)
            if dis < dis_limit :
                out_a.append(ix_pa)
                out_b.append(ix_pb)

    if a_mag >= 0 and b_mag >= 0 and mag_limit != 0 :
        # mag difference limit check
        mag_diff = mag_a[out_a] - mag_b[out_b]
        std = mag_diff.std()
        mag_limit_x = - std * mag_limit if mag_limit < 0 else mag_limit
        ix_m = np.where(np.abs(mag_diff) < mag_limit_x)
        out_a = [out_a[i] for i in ix_m]
        out_b = [out_b[i] for i in ix_m]

    return (out_a, out_b)
