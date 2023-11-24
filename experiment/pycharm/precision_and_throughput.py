import numpy as np
from numpy import linalg as la
import time
import math
import matplotlib
import matplotlib.pyplot as plt
def speed(n):
    speed=(32+4)/(n+4)
    return speed

#计算精度与性能关系
x = list(range(4,33,4))
x_value = []
y = []
for item in x:
    x_value.append(str(item))
    y.append(speed(item))
print(x)
print(y)
y[0] = 3.1
plt.figure(2)
plt.xlabel('Precision: Number of bits')  # x轴标签
plt.ylabel('Speed over 32-bit')  # y轴标签
plt.ylim (0.5,3.3)
for i in range(len(x)):
    plt.bar(x_value[i], y[i])
plt.legend()
plt.show()



