"""
    Merge stars from table
"""

import MySQLdb
from star_match import star_match


if __name__ == "__main__" :

    conn = MySQLdb.connect("localhost", "uvbys", "uvbySurvey", "survey")
    cur = conn.cursor()

    # TODO: merge stars (lzj)
    # load stars for


    cur.close()
    conn.close()
    print ("END")