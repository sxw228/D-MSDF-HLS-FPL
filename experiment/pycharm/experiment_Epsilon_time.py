import cv2
import numpy as np
import imutils
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import rc
from scipy.interpolate import make_interp_spline

from scipy import interpolate
from scipy.interpolate import make_interp_spline
import random
import matplotlib
from matplotlib.patches import Ellipse
from scipy.ndimage import gaussian_filter1d




font = {'size': 12}
matplotlib.rc('font', **font)

def get_point(event, x, y, flags, param):
    # 鼠标单击事件
    if event == cv2.EVENT_LBUTTONDOWN:
        # 输出坐标
        print('坐标值: ', x, y)
        # 在传入参数图像上画出该点
        #cv2.circle(param, (x, y), 1, (255, 255, 255), thickness=-1)
        img = param.copy()
        # 输出坐标点的像素值
        print('像素值：',param[y][x]) # 注意此处反转，(纵，横，通道)
        # 显示坐标与像素
        text = "("+str(x)+','+str(y)+')'+str(param[y][x])
        cv2.putText(img,text,(0,param.shape[0]),cv2.FONT_HERSHEY_PLAIN,1.5,(0,0,255),1)
        cv2.imshow('image', img)
        cv2.waitKey(0)







if __name__ == "__main__":
    gisette = cv2.imread("epsilon_zeke.png",1)

    resized = imutils.resize(gisette, width=1000)


    low_green = np.array([0, 160, 0])
    high_green = np.array([100, 180, 50])
    mask_green = cv2.inRange(resized, low_green, high_green)


    low_blue = np.array([180, 0, 0])
    high_blue = np.array([205, 255, 70])
    mask_blue = cv2.inRange(resized, low_blue, high_blue)

    low_red = np.array([0, 0, 200])
    high_red = np.array([40, 255, 255])
    mask_red = cv2.inRange(resized, low_red, high_red)

    low_black = np.array([0, 0, 0])
    high_black = np.array([1, 1, 1])
    mask_black = cv2.inRange(resized, low_black, high_black)


    # 定义两个窗口 并绑定事件 传入各自对应的参数
    cv2.namedWindow('gisette')
    cv2.setMouseCallback('gisette', get_point, resized)

    x_green = []
    loss_green = []
    for i in range(1000):
        x = mask_green[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_green[middle, i] = 0
            loss_green.append(1.0 * (500 - middle) / 4000)
            x_green.append(10**((i*4/1000)-3))

    x_blue = []
    loss_blue = []
    for i in range(1000):
        x = mask_blue[:, i]
        where_res = np.where(x > 0)
        if(where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_blue[middle,i] = 0
            loss_blue.append(1.0*(500 - middle)/4000)
            x_blue.append(10**((i*4/1000)-3))

    x_red = []
    loss_red = []
    for i in range(1000):
        x = mask_red[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_red[middle, i] = 0
            loss_red.append(1.0*(500 - middle)/4000)
            x_red.append(10**((i*4/1000)-3))

    x_black = []
    loss_black = []
    for i in range(1000):
        x = mask_black[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_black[middle, i] = 0
            loss_black.append(1.0*(500 - middle)/4000)
            x_black.append(10**((i*4/1000)-3))

    loss_list = np.load('loss_list_epsilon_8.npy')
    time_per_epoch = np.load('time_per_epoch_epsilon_8.npy')



    fig = plt.figure(figsize=(8, 5))
    plt.subplot(1, 2, 2)
    plt.xlabel('Time(s)')  # x轴标签
    plt.ylabel('Loss')  # y轴标签

    plt_x_list = []
    time_point = 0
    loss_list_plt = []
    for item in range(100):
        #if (loss_list[item]/1000+0.14 < 0.5):
        loss_list_plt.append(loss_list[item]/40000+0.0125)
        time_point = time_point + 140 * time_per_epoch[item] / (1600 * 1000000)
        plt_x_list.append(time_point)

    plt_x_list_zeke = []
    time_point = 0
    loss_list_plt_zeke = []
    for item in range(100):
        loss_list_plt_zeke.append(loss_list[item]/40000+0.0125)
        time_point = time_point + 825000 / (800 * 1000000)
        plt_x_list_zeke.append(time_point)

    plt.ylim(0.04, 0.1)

    plt.plot(plt_x_list, loss_list_plt, linewidth=2, linestyle="solid", label=r"MSDF-4(Ours)")
    plt.plot(plt_x_list_zeke, loss_list_plt_zeke, linewidth=2, linestyle="solid", label=r"MLWeaving-4")

    new_x_black = np.linspace(min(x_black), max(x_black), 10)
    y_smoothed_black = make_interp_spline(x_black, loss_black,3)(new_x_black)
    new_x_blue = np.linspace(min(x_blue), max(x_blue), 10)
    y_smoothed_blue = make_interp_spline(x_blue, loss_blue,3)(new_x_blue)
    new_x_red = np.linspace(min(x_red), max(x_red), 10)
    y_smoothed_red = make_interp_spline(x_red, loss_red,3)(new_x_red)

    y_smoothed_black = gaussian_filter1d(y_smoothed_black, sigma=2,mode="nearest")
    y_smoothed_blue = gaussian_filter1d(y_smoothed_blue, sigma=2,mode="nearest")
    y_smoothed_red = gaussian_filter1d(y_smoothed_red, sigma=2,mode="nearest")



    # 默认颜色，如果想更改颜色，可以增加参数color='red',这是红色。
    plt.plot(new_x_black, y_smoothed_black, linewidth=2, linestyle="solid", label=r'MLWeaving-32')
    plt.plot(new_x_blue, y_smoothed_blue, linewidth=2, linestyle="solid", label=r"MA-32")
    plt.plot(new_x_red, y_smoothed_red, linewidth=2, linestyle="solid", label=r"HOG-32")
    plt.legend(bbox_to_anchor=(0.5, 1.05), loc=8, borderaxespad=0, ncol=2)
    plt.title('(b) Epsilon (loss vs. time)',x=0.5,y=-0.3)

    plt.subplot(1,2,1)
    gisette = cv2.imread("gisette_time.png", 1)

    crop = gisette[:, 24:1051]
    resized = imutils.resize(crop, width=1000)
    crop = resized[15:515, :]

    low_green = np.array([0, 160, 0])
    high_green = np.array([100, 180, 50])
    mask_green = cv2.inRange(crop, low_green, high_green)

    low_blue = np.array([180, 0, 0])
    high_blue = np.array([205, 255, 70])
    mask_blue = cv2.inRange(crop, low_blue, high_blue)

    low_red = np.array([0, 0, 200])
    high_red = np.array([40, 255, 255])
    mask_red = cv2.inRange(crop, low_red, high_red)

    low_black = np.array([0, 0, 0])
    high_black = np.array([1, 1, 1])
    mask_black = cv2.inRange(crop, low_black, high_black)

    # 定义两个窗口 并绑定事件 传入各自对应的参数
    cv2.namedWindow('gisette')
    cv2.setMouseCallback('gisette', get_point, crop)

    x_green = []
    loss_green = []
    for i in range(1000):
        x = mask_green[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_green[middle, i] = 0
            loss_green.append(1.0 * (500 - middle) / 1000)
            x_green.append(10 ** ((i * 3 / 1000) - 3))

    x_blue = []
    loss_blue = []
    for i in range(1000):
        x = mask_blue[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_blue[middle, i] = 0
            loss_blue.append(1.0 * (500 - middle) / 1000-0.01)
            x_blue.append(10 ** ((i * 3 / 1000) - 3))

    x_red = []
    loss_red = []
    for i in range(1000):
        x = mask_red[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_red[middle, i] = 0
            loss_red.append(1.0 * (500 - middle) / 1000-0.01)
            x_red.append(10 ** ((i * 3 / 1000) - 3))

    x_black = []
    loss_black = []
    for i in range(1000):
        x = mask_black[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_black[middle, i] = 0
            loss_black.append(1.0 * (500 - middle) / 1000)
            x_black.append(10 ** ((i * 3 / 1000) - 3))

    loss_list = np.load('loss_list.npy')
    time_per_epoch = np.load('time_per_epoch.npy')

    plt.xlabel('Time(s)')  # x轴标签
    plt.ylabel('Loss')  # y轴标签


    plt_x_list = []
    time_point = 0
    loss_list_plt = []
    for item in range(100):
        if (loss_list[item] / 1000 + 0.14 < 0.5):
            loss_list_plt.append(loss_list[item] / 1000 + 0.14)
            time_point = time_point + 140 * time_per_epoch[item] / (400 * 1000000)
            plt_x_list.append(time_point)

    plt_x_list_zeke = []
    time_point = 0
    loss_list_plt_zeke = []

    for item in range(100):
        if (loss_list[item] / 1000 + 0.14 < 0.5):
            loss_list_plt_zeke.append(loss_list[item] / 1000 + 0.14)
            time_point = time_point + 825000 / (400 * 1000000)
            plt_x_list_zeke.append(time_point)

    plt.ylim(0.1, 0.41)

    plt.plot(plt_x_list, loss_list_plt, linewidth=2, linestyle="solid", label=r"MSDF-4(Ours)")
    plt.plot(plt_x_list_zeke, loss_list_plt_zeke, linewidth=2, linestyle="solid",
             label=r"MLWeaving-4")

    y_smoothed_green = gaussian_filter1d(loss_green, sigma=40)
    y_smoothed_blue = gaussian_filter1d(loss_blue, sigma=40)
    y_smoothed_red = gaussian_filter1d(loss_red, sigma=40)

    # 默认颜色，如果想更改颜色，可以增加参数color='red',这是红色。
    plt.plot(x_green, y_smoothed_green, linewidth=2, linestyle="solid",
             label=r'MLWeaving-32')
    plt.plot(x_blue, y_smoothed_blue, linewidth=2, linestyle="solid", label=r"MA-32")
    plt.plot(x_red, y_smoothed_red, linewidth=2, linestyle="solid", label=r"HOG-32")

    plt.plot([plt_x_list[-1], plt_x_list[-1], ], [0, loss_list_plt[-1]], 'k--', linewidth=2)
    plt.plot([plt_x_list_zeke[-1], plt_x_list_zeke[-1], ], [0, loss_list_plt_zeke[-1]], 'k--', linewidth=2)
    plt.plot([x_red[-1], x_red[-1], ], [0, y_smoothed_red[-1]], 'k--', linewidth=2)
    plt.arrow(plt_x_list_zeke[-1], 0.13, plt_x_list[-1]-plt_x_list_zeke[-1], 0, length_includes_head=True, head_width=0.01, fc='b', ec='k')

    plt.legend(bbox_to_anchor=(0.5, 1.05), loc=8, borderaxespad=0, ncol=2)
    plt.title('(a) Gisette (loss vs. time)',x=0.5,y=-0.3)

    plt.tight_layout()
    fig.tight_layout()




    plt.savefig('loss_time.eps', dpi=1200, bbox_inches='tight')
    plt.show()






