import numpy as np
import csv
import sys

data_file_name = sys.argv[1]

values = np.loadtxt(data_file_name)

line_space=np.linspace(1,values.size,values.size)

coefficient=np.polyfit(line_space,values,1)

if coefficient[0] > 0:
  print("1")
else:      
  if coefficient[0] < 0:
    print("-1")
  else:
    print("0")
