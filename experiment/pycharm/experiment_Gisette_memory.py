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

# interpld
def spline1(x, y, point):
    x = np.array(x)
    y = np.array(y)
    f = interpolate.interp1d(x, y, kind="cubic")  #曲线绘制方法1
    X = np.linspace(x.min(), x.max(), num=point, endpoint=True)
    Y = f(X)
    return X, Y


if __name__ == "__main__":
    gisette = cv2.imread("gisette_epoch.png",1)

    crop = gisette[:, 31:918]

    resized = imutils.resize(crop, width=450)

    crop = resized[14:314, :]

    low_blue = np.array([180, 0, 0])
    high_blue = np.array([200, 255, 20])
    mask_blue = cv2.inRange(crop, low_blue, high_blue)

    low_red = np.array([0, 0, 200])
    high_red = np.array([20, 255, 255])
    mask_red = cv2.inRange(crop, low_red, high_red)

    low_black = np.array([0, 0, 0])
    high_black = np.array([1, 1, 1])
    mask_black = cv2.inRange(crop, low_black, high_black)


    # 定义两个窗口 并绑定事件 传入各自对应的参数
    cv2.namedWindow('gisette')
    cv2.setMouseCallback('gisette', get_point, crop)

    x_blue = []
    loss_blue = []
    for i in range(450):
        x = mask_blue[:, i]
        where_res = np.where(x > 0)
        if(where_res[0].shape[0]):
            #middle = (where_res[0][0]+where_res[0][-1])//2
            middle = where_res[0][0]
            print(middle)
            mask_blue[middle,i] = 0
            loss_blue.append(1.0*(300 - middle)/1000)
            x_blue.append(i)

    x_red = []
    loss_red = []
    for i in range(450):
        x = mask_red[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_red[middle, i] = 0
            loss_red.append(1.0*(300 - middle)/1000)
            x_red.append(i)

    x_black = []
    loss_black = []
    for i in range(450):
        x = mask_black[:, i]
        where_res = np.where(x > 0)
        if (where_res[0].shape[0]):
            middle = where_res[0][0]
            print(middle)
            mask_black[middle, i] = 0
            loss_black.append(1.0*(300 - middle)/1000)
            x_black.append(i)

    x_train_loss = range(450)  # loss的数量，即x轴
    fig = plt.figure()
    plt.xlabel('Epochs')  # x轴标签
    plt.ylabel('Loss')  # y轴标签

    xy_s_blue = smooth_xy(x_blue, loss_blue)
    xy_s_red = smooth_xy(x_red, loss_red)
    xy_s_black = smooth_xy(x_black, loss_black)

    msdf_sgd_epoch =[]
    for item in xy_s_black[1]:
        msdf_sgd_epoch.append(item)

    # 默认颜色，如果想更改颜色，可以增加参数color='red',这是红色。
    plt.plot(x_blue, loss_blue, linewidth=3, linestyle="solid", label=r"ModelAverage, $\lambda$=1/2^8, $\beta$=0.98")
    plt.plot(x_red, loss_red, linewidth=3, linestyle="solid", label=r"Hogwild, $\lambda$=1/2^11, $\beta$=0.98")
    plt.plot(x_black, loss_black, linewidth=3, linestyle="solid", label=r'MLWeaving-8bit, $\lambda$=1/2^8, $\alpha$=12')
    plt.plot(x_black, loss_black, linewidth= 2, linestyle="solid", label=r'MFSD-SGD-8bit, $\lambda$=1/2^8, $\alpha$=12')
    plt.legend()
    plt.title('Gisette(loss vs. epoch)')

    fig.canvas.draw()
    # convert canvas to image
    img = np.fromstring(fig.canvas.tostring_rgb(), dtype=np.uint8,
                        sep='')
    img = img.reshape(fig.canvas.get_width_height()[::-1] + (3,))
    # img is rgb, convert to opencv's default bgr
    img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)

    cv2.imwrite("Gisette(loss vs. epoch).png",img)

    # 显示图像
    while(True):
        cv2.imshow('plt', img)
        cv2.imshow('gisette', crop)
        cv2.imshow('mask_blue', mask_blue)
        cv2.imshow('mask_red', mask_red)
        cv2.imshow('mask_black', mask_black)


        if cv2.waitKey(20) & 0xFF == 27:
            break







