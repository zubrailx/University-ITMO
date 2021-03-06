from modules.util import Color, color_string
from modules.util import ProjectException

import labs.lab_1 as lab_1
import labs.lab_2 as lab_2
import labs.lab_3 as lab_3
import labs.lab_4 as lab_4
import labs.lab_5 as lab_5


labs = {
    1: lab_1.solve,
    2: lab_2.solve,
    3: lab_3.solve,
    4: lab_4.solve,
    5: lab_5.solve
}


def solve(lab_number, input_file, output_file):
    if (lab_number in labs.keys()):
        labs[lab_number](input_file, output_file)
    else:
        raise ProjectException(color_string(Color.RED, f"ERROR >> Lab with number {lab_number} number is not realized. " 
                                            "Terminating..."))
