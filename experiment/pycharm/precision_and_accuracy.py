import numpy as np
from numpy import linalg as la
import time
import math
import matplotlib
import matplotlib.pyplot as plt

#计算提前终止加速效果
ET_time_list_mnist = [90.62,90.63,93.64]
ET_time_list_epsilon = [85.9,86.2,86.0]
ET_time_list_gisette = [97.4,97.5,97.5]
ET_speed_list_gisette = []
ET_speed_list_epsilon = []
ET_speed_list_mnist = []
for item in ET_time_list_gisette:
    ET_speed_list_gisette.append(item)
for item in ET_time_list_epsilon:
    ET_speed_list_epsilon.append(item)
for item in ET_time_list_mnist:
    ET_speed_list_mnist.append(item)
x_value =  ['MNIST','Epsilon','Gisette']

x = np.arange(0,3*5,5)
width = 1  # the width of the bars

#fig, (ax1, ax2) = plt.subplots(nrows=1, ncols=2,figsize=(14, 3))
fig, ax2 = plt.subplots(figsize=(7, 2))

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

rects1  = ax2.bar(x - width, bit_8_list, width=width, label='MSDF-4', edgecolor='black', color="maroon")
rects2  = ax2.bar(x, bit_16_list, width=width, label='MSDF-8', edgecolor='black', color="steelblue")
rects3  = ax2.bar(x + width, bit_32_list, width=width, label='MSDF-16', edgecolor='black', color="olivedrab")

# Add some text for labels, title and custom x-axis tick labels, etc.
#ax2.set_title("(b) Effect of early termination")
#ax2.set_ylim(0,3)
ax2.spines['top'].set_visible(False)
ax2.spines['right'].set_visible(False)
ax2.set_ylabel('Accuracy')
#ax2.set_ylim(0,100)
ax2.set_xticks(x)
ax2.set_xticklabels(x_value)
#ax2.set_title("Classification accuracy")
#ax2.set_title("Classification accuracy",x=8,y=100)
ax2.legend(bbox_to_anchor=(1.01, 0.5), loc=6, borderaxespad=0, ncol=1)


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

fig.tight_layout()
plt.savefig('precision_and_accuracy_camera_ready.eps',dpi=1200, bbox_inches='tight')
plt.show()


