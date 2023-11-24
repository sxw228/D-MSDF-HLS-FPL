import numpy as np
from numpy import linalg as la
import time
import math
import matplotlib
import matplotlib.pyplot as plt

#计算提前终止加速效果
ET_time_list_gisette = [0.61504,0.62457,0.63465]
ET_time_list_epsilon = [0.820391,0.8072145,0.82825935]
ET_time_list_mnist = [0.49397,0.49549,0.501037]
ET_speed_list_gisette = []
ET_speed_list_epsilon = []
ET_speed_list_mnist = []
for item in ET_time_list_gisette:
    ET_speed_list_gisette.append(1.0/item)
for item in ET_time_list_epsilon:
    ET_speed_list_epsilon.append(1.0 / item)
for item in ET_time_list_mnist:
    ET_speed_list_mnist.append(1.0 / item)
x_value =  ['MNIST','Epsilon','Gisette']

x = np.arange(0,3*6,6)
width = 1.5  # the width of the bars

fig, (ax1, ax2) = plt.subplots(nrows=2, ncols=1,figsize=(6, 6))

bit_8_list = []
bit_16_list = []
bit_32_list = []

bit_8_list.append(ET_speed_list_mnist[2])
bit_8_list.append(ET_speed_list_epsilon[2])
bit_8_list.append(ET_speed_list_gisette[2])
bit_16_list.append(ET_speed_list_mnist[1])
bit_16_list.append(ET_speed_list_epsilon[1])
bit_16_list.append(ET_speed_list_gisette[1])
bit_32_list.append(ET_speed_list_mnist[0])
bit_32_list.append(ET_speed_list_epsilon[0])
bit_32_list.append(ET_speed_list_gisette[0])

rects1  = ax2.bar(x - 1.7, bit_8_list, width=width, label='MSDF-4', edgecolor='black', color="maroon")
rects2  = ax2.bar(x, bit_16_list, width=width, label='MSDF-8', edgecolor='black', color="steelblue")
rects3  = ax2.bar(x + 1.7, bit_32_list, width=width, label='MSDF-16', edgecolor='black', color="olivedrab")

# Add some text for labels, title and custom x-axis tick labels, etc.
ax2.set_title("(b) Speedup with Early Termination")
ax2.set_ylim(0,3)

ax2.set_ylabel('Speedup with early termination')
ax2.set_xticks(x)
ax2.set_xticklabels(x_value)
ax2.legend()
ax2.hlines(1, -3, 15,color="red", linestyles="--")#横线

def autolabel1(rects):
    """Attach a text label above each bar in *rects*, displaying its height."""
    for rect in rects:
        height = rect.get_height()
        ax1.annotate(str(height)[:4],
                    xy=(rect.get_x() + rect.get_width() / 2, height),
                    xytext=(0, 3),  # 3 points vertical offset
                    textcoords="offset points",
                    ha='center', va='bottom')
def autolabel2(rects):
    """Attach a text label above each bar in *rects*, displaying its height."""
    for rect in rects:
        height = rect.get_height()
        ax2.annotate(str(height)[:4],
                    xy=(rect.get_x() + rect.get_width() / 2, height),
                    xytext=(0, 3),  # 3 points vertical offset
                    textcoords="offset points",
                    ha='center', va='bottom')

autolabel2(rects1)
autolabel2(rects2)
autolabel2(rects3)

plt.savefig('experiment_et.png',dpi=600, bbox_inches='tight')

def speed(x_list):
    speed_4 = (32 + 5) / (8 + 4) * x_list[2]/x_list[0]
    speed_8 = (32 + 5) / (8 + 5) * x_list[2]/x_list[0]
    speed_16 = (32 + 5) / (16 + 5) * x_list[1]/x_list[0]
    speed_32 = (32 + 5) / (32 + 5) * x_list[0]/x_list[0]
    return [speed_4,speed_8,speed_16,speed_32]


#计算精度与性能关系

y_gisette = []
y_epsilon = []
y_mnist = []



y_gisette = speed(ET_speed_list_gisette)
y_epsilon = speed(ET_speed_list_epsilon)
y_mnist = speed(ET_speed_list_mnist)

bit_4_list = []
bit_8_list = []
bit_16_list = []
bit_32_list = []

bit_4_list.append(y_mnist[0])
bit_4_list.append(y_epsilon[0])
bit_4_list.append(y_gisette[0])
bit_8_list.append(y_mnist[1])
bit_8_list.append(y_epsilon[1])
bit_8_list.append(y_gisette[1])
bit_16_list.append(y_mnist[2])
bit_16_list.append(y_epsilon[2])
bit_16_list.append(y_gisette[2])
bit_32_list.append(y_mnist[3])
bit_32_list.append(y_epsilon[3])
bit_32_list.append(y_gisette[3])

ax1.set_title("(a) Speedup with Arbitrary Precision")

ax1.set_ylabel('Speedup versus MSDF-16')  # y轴标签
ax1.set_ylim (0,4.3)

x = np.arange(0,3*6,6)

wid_=1

rects4 = ax1.bar(x-1.5, bit_4_list, edgecolor='black', label='MSDF-2', color="gold")
rects5 = ax1.bar(x-0.5, bit_8_list, edgecolor='black', label='MSDF-4', color="maroon")
rects6 = ax1.bar(x+0.5, bit_16_list, edgecolor='black', label='MSDF-8', color="steelblue")
rects7 = ax1.bar(x+1.5, bit_32_list, edgecolor='black', label='MSDF-16', color="olivedrab")

ax1.set_xticks(x)
ax1.set_xticklabels(x_value)



ax1.hlines(1, -2.5, 14.5, color="red", linestyles="--")#横线
ax1.legend(ncol=2)
autolabel1(rects4)
autolabel1(rects5)
autolabel1(rects6)
autolabel1(rects7)
fig.tight_layout()
plt.savefig('experiment_precision_camera_ready.eps',dpi=1200, bbox_inches='tight')
plt.show()


