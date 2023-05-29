import gmpy2

class OnlineRadix2:
    name = ''

    def __init__(self, temp):
        self.name = temp
        self.PRECISION = 100
        self.res_list = []
        gmpy2.get_context().precision = 100
    def read_data_from_txt(self, pdata_x, pdata_y):
        with open("F:/msdf/online_mult_ver_two-master/online_mult_ver_two-master/x_value_th.txt", 'r') as f:
            for line in f:
                if line == "00\n":
                    pdata_x.append(0)
                elif line == "01\n":
                    pdata_x.append(-1)
                elif line == "10\n":
                    pdata_x.append(1)
                else:
                    pdata_x.append(0)
        with open("F:/msdf/online_mult_ver_two-master/online_mult_ver_two-master/y_value_th.txt", 'r') as f:
            for line in f:
                if line == "00\n":
                    pdata_y.append(0)
                elif line == "01\n":
                    pdata_y.append(-1)
                elif line == "10\n":
                    pdata_y.append(1)
                else:
                    pdata_y.append(0)

    def output(self):
        with open('F:/msdf/online_mult_ver_two-master/online_mult_ver_two-master/z_python.txt', 'w') as f:
            for item in self.res_list:
                if item == 0:
                    f.writelines("00\n")
                elif item == 1:
                    f.writelines("10\n")
                else:
                    f.writelines("01\n")


    #   -pdata_x
    #   待计算的输入X的2进制序列, 且必须满足X∈(-1, 1), 如01001
    #   -pdata_y
    #   待计算的输入Y的2进制序列, 且必须满足Y∈(-1, 1), 如0 - 1110
    #   -accurate_set
    #   需要计算的数据精度, 默认为0, 代表自动调整
    #   -isPrint
    #   是否需要打印过程, 默认不打印
    #   函数描述: Online格式2进制乘法器
    def online_multiply(self, pdata_x, pdata_y, accurate_set, isPrint):
        #   结果列表
        self.res_list = []
        #   乘数的索引
        iter_x = 0
        iter_y = 0
        #   初始数据
        input_x = gmpy2.mpz(0)
        input_y = gmpy2.mpz(0)
        #   CA-Reg
        x_data_last = gmpy2.mpz(0)
        x_data = gmpy2.mpz(0)
        y_data = gmpy2.mpz(0)
        #   迭代数据
        w_data = gmpy2.mpz(0)
        v_data = gmpy2.mpz(0)
        p_data = gmpy2.mpz(0)
        t_data = gmpy2.mpz(0)
        #   偏差
        offset = gmpy2.mpz(0)

        #   迭代次数
        vec_len = len(pdata_x)
        iterate_len = vec_len+3
        if accurate_set > 0:
            iterate_len = accurate_set + 4
        #   显示长度
        show_len = 0

        #   遍历整个列表
        for i in range(iterate_len):
            #   获取当前数据
            if i < vec_len:
                #   保存数据输入
                input_x = pdata_x[iter_x]
                input_y = pdata_y[iter_y]
                x_data = x_data + (input_x << (self.PRECISION - 1 - i))
                y_data = y_data + (input_y << (self.PRECISION - 1 - i))
                iter_x = iter_x + 1
                iter_y = iter_y + 1
                show_len = i + 1
            else:
                input_x = 0
                input_y = 0
                offset = vec_len - i - 1
            #   计算V
            v_data = 2 * w_data + ((input_x * y_data) >> 5) + ((input_y * x_data_last) >> 5)
            #   计算P
            v_data_str = v_data.digits(2)
            if v_data_str == '0':
                p_data = 0
            elif v_data_str[0] == '-':
                sub_str = v_data_str[1:]
                str_len = len(sub_str)
                completion = ""
                for j in range(self.PRECISION-str_len):
                    completion = completion + "0"
                sub_str_completion = completion + sub_str
                if sub_str_completion[0:3] == "000":
                    p_data = 0
                else:
                    p_data = -1
            else:
                sub_str = v_data_str[0:]
                str_len = len(sub_str)
                completion = ""
                for j in range(self.PRECISION - str_len):
                    completion = completion + "0"
                sub_str_completion = completion + sub_str
                if sub_str_completion[0:3] == "000":
                    p_data = 0
                else:
                    p_data = 1
            #   得到W
            if i < 3:
                w_data = v_data
            else:
                w_data = v_data - (p_data << (self.PRECISION-2))
            #   保存
            x_data_last = x_data
            #   前4个不算
            if i==5:
                fuck = 0
            if i >=4 :
                self.res_list.append(p_data)
online = OnlineRadix2('老王')
pdata_x = []
pdata_y = []
online.read_data_from_txt(pdata_x, pdata_y)
online.online_multiply(pdata_x[0:100],pdata_y[0:100],100,0)
online.output()
# 设置精度
gmpy2.get_context().precision=100

# 加法
a = gmpy2.mpz(-6)
b = gmpy2.mpz( 987654321)
c = gmpy2.add(a, b)
print(c)
a_str = a.digits(2)
sub_str = a_str[0:3]
# 减法
d = gmpy2.mpz(123456789)
e = gmpy2.mpz(987654321)
f = gmpy2.sub(d, e)
print(f)

# 乘法
g = gmpy2.mpz(123456789)
h = gmpy2.mpz(987654321)
i = gmpy2.mul(g, h)
print(i)

# 除法
j = gmpy2.mpz(123456789)
k = gmpy2.mpz(987654321)
l = gmpy2.div(j, k)
print(l)



