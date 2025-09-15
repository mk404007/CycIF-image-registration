import os
import sys
import cycIFAAP
import FiReTiTiPyLib
from FiReTiTiPyLib.CyclicIF import CyclicIF_Registration

cycreg = CyclicIF_Registration.CyclicIF_Registration(Reverse=True,Copyright="Copyright")     #"Reverse=True" means that the base image of the registration will be the last round of staining. If we put nothing or Reverse=False, it will be the first round.
nbErrors = cycreg.Run(sys.argv[1], sys.argv[2])       #Target directories for images defined in input parameters (1st param: input directory, 2nd param: output directory)