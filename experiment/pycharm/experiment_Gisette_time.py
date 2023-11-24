import cv2
import numpy as np
import imutils
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib import rc
from scipy.interpolate import make_interp_spline

from scipy import interpolate

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


def smooth_xy(lx, ly):
    """数据平滑处理

    :param lx: x轴数据，数组
    :param ly: y轴数据，数组
    :return: 平滑后的x、y轴数据，数组 [slx, sly]
    """
    x = np.array(lx)
    y = np.array(ly)
    x_smooth = np.linspace(x.min(), x.max(), 4500)
    y_smooth = make_interp_spline(x, y)(x_smooth)
    return [x_smooth, y_smooth]




if __name__ == "__main__":
    gisette = cv2.imread("gisette_time.png",1)

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
            # middle = (where_res[0][0]+where_res[0][-1])//2
            middle = where_res[0][0]
            print(middle)
            mask_green[middle, i] = 0
            loss_green.append(1.0 * (500 - middle) / 1000)
            x_green.append(10**((i*3/1000)-3))

    x_blue = []
    loss_blue = []
    for i in range(1000):
        x = mask_blue[:, i]
        where_res = np.where(x > 0)
        if(where_res[0].shape[0]):
            #middle = (where_res[0][0]+where_res[0][-1])//2
            middle = where_res[0][0]
            print(middle)
            mask_blue[middle,i] = 0
            loss_blue.append(1.0*(500 - middle)/1000)
            x_blue.append(10**((i*3/1000)-3))

    x_red = []
    loss_red = []
    for i in range(1000):
        x = mask_red[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_red[middle, i] = 0
            loss_red.append(1.0*(500 - middle)/1000)
            x_red.append(10**((i*3/1000)-3))

    x_black = []
    loss_black = []
    for i in range(1000):
        x = mask_black[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_black[middle, i] = 0
            loss_black.append(1.0*(500 - middle)/1000)
            x_black.append(10**((i*3/1000)-3))

    loss_list = np.load('loss_list.npy')
    time_per_epoch = np.load('time_per_epoch.npy')



    fig = plt.figure(figsize=(12, 6))
    plt.xlabel('Time(s)')  # x轴标签
    plt.ylabel('Loss')  # y轴标签
    plt.xscale("log")

    plt_x_list = []
    time_point = 0
    loss_list_plt = []
    for item in range(100):
        if (loss_list[item]/1000+0.14 < 0.5):
            loss_list_plt.append(loss_list[item]/1000+0.14)
            time_point = time_point + 140 * time_per_epoch[item] / (400 * 1000000)
            plt_x_list.append(time_point)

    plt_x_list_zeke = []
    time_point = 0
    loss_list_plt_zeke = []
    for item in range(100):
        if (loss_list[item]/1000+0.14 < 0.5):
            loss_list_plt_zeke.append(loss_list[item]/1000+0.14)
            time_point = time_point + 825000 / (400 * 1000000)
            plt_x_list_zeke.append(time_point)

    plt.ylim(0.1, 0.41)

    plt.plot(plt_x_list, loss_list_plt, linewidth=3, linestyle="solid", label=r"Msdf-8, $\lambda$=1/2^7")
    plt.plot(plt_x_list_zeke, loss_list_plt_zeke, linewidth=3, linestyle="solid", label=r"MLWeaving-4, $\lambda$=1/2^7, $\alpha$=40")

    y_smoothed_green = gaussian_filter1d(loss_green, sigma=40)
    y_smoothed_blue = gaussian_filter1d(loss_blue, sigma=40)
    y_smoothed_red = gaussian_filter1d(loss_red, sigma=40)

    # 默认颜色，如果想更改颜色，可以增加参数color='red',这是红色。
    plt.plot(x_green, y_smoothed_green, linewidth=3, linestyle="solid", label=r'MLWeaving-32, $\lambda$=1/2^7, $\alpha$=40')
    plt.plot(x_blue, y_smoothed_blue, linewidth=3, linestyle="solid", label=r"MA-32, $\lambda$=1/2^8, $\beta$=1.0")
    plt.plot(x_red, y_smoothed_red, linewidth=3, linestyle="solid", label=r"HOG-32, $\lambda$=1/2^9, $\beta$=1.0")
    #plt.plot(x_black, loss_black, linewidth=3, linestyle="solid", label=r'MLWeaving-4bit, $\lambda$=1/2^7, $\alpha$=40')
    plt.legend()
    plt.title('(a) Gisette(loss vs. time)')
    plt.savefig('Gisette(loss vs. time).png', dpi=600, bbox_inches='tight')
    fig.canvas.draw()
    # convert canvas to image
    img = np.fromstring(fig.canvas.tostring_rgb(), dtype=np.uint8,
                        sep='')
    img = img.reshape(fig.canvas.get_width_height()[::-1] + (3,))
    # img is rgb, convert to opencv's default bgr
    img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)

    #cv2.imwrite("Gisette(loss vs. time).png",img)

    # 显示图像
    while(True):
        cv2.imshow('gisette', crop)
        cv2.imshow('plt', img)
        cv2.imshow('mask_blue', mask_blue)
        cv2.imshow('mask_red', mask_red)
        cv2.imshow('mask_black', mask_black)
        cv2.imshow('mask_green', mask_green)


        if cv2.waitKey(20) & 0xFF == 27:
            break







