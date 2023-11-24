import numpy as np
from numpy import linalg as la
import time
import math
import matplotlib
import matplotlib.pyplot as plt

ET_time_list_gisette = [0.61504,0.62457,0.63465]
ET_time_list_epsilon = [0.820391,0.8072145,0.82825935]
MSDF_32=[7.8/4/0.61504 ,2/0.820391]
MSDF_8=[7.8/0.61504, 8/0.820391]
MLW_32=[1.0,1.0]
MLW_4=[7.8,8]
HOG_32=[2.1,1.5]
HOG_8=[1.0,1.2]
MA_32=[3.4,3.8]
MA_8=[6.9,8.9]

width=1.5
fig, (ax1, ax2) = plt.subplots(nrows=1, ncols=2,figsize=(9, 3))
x = np.arange(0,2*12,12)
x_value = ['Gisette', 'Epsilon']
#rects1  = ax1.bar(x -3.5, MSDF_32, width=width, label='MSDF_32', edgecolor='black')
rects1  = ax1.bar(x - 3 * width, MSDF_8, width=width, label='MSDF-4(Ours)', edgecolor='black', color='#3b6291')
rects3  = ax1.bar(x - 2 * width, MLW_4, width=width, label='MLWeaving-4', edgecolor='black', color='#779043')
rects7  = ax1.bar(x - 1 * width, MA_8, width=width, label='MA-8', edgecolor='black', color='#0780cf')
rects5  = ax1.bar(x + 0 * width, HOG_8, width=width, label='HOG-8', edgecolor='black', color='#388498')
rects2  = ax1.bar(x + 1 * width, MLW_32, width=width, label='MLWeaving-32', edgecolor='black', color='#943c39')
rects6  = ax1.bar(x + 2 * width, MA_32, width=width, label='MA-32', edgecolor='black', color='#bf7334')
rects4  = ax1.bar(x + 3 * width, HOG_32, width=width, label='HOG-32', edgecolor='black', color='#624c7c')




ax1.set_title("(a) Normalized throughput")
ax1.set_ylim(0,15)
ax1.set_ylabel('Normalized throughput')
ax1.set_xticks(x)
ax1.set_xticklabels(x_value)
#ax1.legend(bbox_to_anchor=(1.01, 0.5), loc=6, borderaxespad=0, ncol=1)

def autolabel1(rects):
    """Attach a text label above each bar in *rects*, displaying its height."""
    for rect in rects:
        height = rect.get_height()
        ax1.annotate(str(height)[:5],
                    xy=(rect.get_x() + rect.get_width() / 2, height),
                    xytext=(0, 3),  # 3 points vertical offset
                    textcoords="offset points",
                    ha='center', va='bottom')

# autolabel1(rects1)
# autolabel1(rects2)
# autolabel1(rects3)
# autolabel1(rects4)
# autolabel1(rects5)
# autolabel1(rects6)
# autolabel1(rects7)
MSDF_8=[0.125*0.61504, 0.125*0.820391]
MLW_32=[1.0,1.0]
MLW_4=[0.125,0.125]
HOG_32=[0.96,0.89]
HOG_8=[0.2,0.2]
MA_32=[1.0,0.9]
MA_8=[0.2,0.2]

width=1
x = np.arange(0,2*8,8)
x_value = ['Gisette', 'Epsilon']

rects1  = ax2.bar(x -2.5, MSDF_8, width=width, label='MSDF-4(Ours)', edgecolor='black', color='#3b6291')
rects3  = ax2.bar(x -1.5, MLW_4, width=width, label='MLWeaving-4', edgecolor='black', color='#779043')
rects7  = ax2.bar(x -0.5, MA_8, width=width, label='MA-8', edgecolor='black', color='#0780cf')
rects5  = ax2.bar(x +0.5, HOG_8, width=width, label='HOG-8', edgecolor='black', color='#388498')
rects2  = ax2.bar(x +1.5, MLW_32, width=width, label='MLWeaving-32', edgecolor='black', color='#943c39')
rects6  = ax2.bar(x +2.5, MA_32, width=width, label='MA-32', edgecolor='black', color='#bf7334')
rects4  = ax2.bar(x +3.5, HOG_32, width=width, label='HOG-32', edgecolor='black', color='#624c7c')
ax2.set_title("(b) Normalized memory traffic")
ax2.set_ylim(0,1.2)
ax2.set_ylabel('Normalized memory traffic')
ax2.set_xticks(x)
ax2.set_xticklabels(x_value)
ax2.legend(bbox_to_anchor=(1.01, 0.5), loc=6, borderaxespad=0, ncol=1)

def autolabel2(rects):
    """Attach a text label above each bar in *rects*, displaying its height."""
    for rect in rects:
        height = rect.get_height()
        ax2.annotate(str(height)[:5],
                    xy=(rect.get_x() + rect.get_width() / 2, height),
                    xytext=(0, 3),  # 3 points vertical offset
                    textcoords="offset points",
                    ha='center', va='bottom')
# autolabel2(rects1)
# autolabel2(rects2)
# autolabel2(rects3)
# autolabel2(rects4)
# autolabel2(rects5)
# autolabel2(rects6)
# autolabel2(rects7)
fig.tight_layout()
plt.savefig('experiment_throughput_camera_ready.eps',dpi=1200, bbox_inches='tight')
plt.show()

