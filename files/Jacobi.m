%function [ x,k,index]=Jacobi(A,b,ep,it_max)
% 求线性方程组的雅可比迭代法，其中，
% A为方程组的系数矩阵；
% b为方程组的右端项;
% ep为精度要求，缺省值为1e-5;
% it_max为最大迭代次数，缺省值为100;
% x为方程组的解;
% k为迭代次数;
% index为指标变量，index=0表示迭代失败，index=1表示收敛到指定要求,
clear
clc
A=[25 0 1 2 1;
   2 26 2 0 3;
   2 0 27 2 1;
   0 2 4 28 0;
   0 2 2 2 29];
A(1,:)=A(1,:)/25;
A(2,:)=A(2,:)/26;
A(3,:)=A(3,:)/27;
A(4,:)=A(4,:)/28;
A(5,:)=A(5,:)/29;
q_16 = quantizer('fixed', 'Round', 'Saturate', [17 16]);
A_list = num2bin(q_16,A);
A_q = bin2num(q_16,A_list);
A_q = reshape(A_q, 5, 5);
A_q = A_q';
% 增广矩阵
b=[1/5;2/6;3/7;4/8;5/9];
b_list = num2bin(q_16,b);
b_q = bin2num(q_16,b_list);
A = A_q;
b = b_q;
it_max =100;
ep = 1e-5;


 
 

[n,m] = size(A);nb = length(b);
%当方程组行与列的维数不相等时，停止计算，并输出出错信息。
if n ~=m
        error('The rows and columns of matrix A must be equal! ');
        return;
end
% 当方程组与右端项的维数不匹配时，停止计算，并输出出错信息。
if m~=nb
        error ('The columns of A must be equal the length of b! ');
        return;
end



k=0;x = zeros (n,1);y=zeros (n,1);index=1;
epoch=0;
while 1
    epoch = epoch+1;
    fprintf('第%d轮\n',epoch);
    for i=1 :n
            y(i) =b(i) ;
            SUM = 0;
            for j=1:n
                if j~=i
                        SUM = SUM+A(i,j)*x(j);
                end
            end
            fprintf('第%d行的SUM = %f\n',i,SUM);
            y(i) = y(i) - SUM;
            if abs(A(i,i))<1e-10  &&k==it_max       % abs绝对值函数
                index =0 ;return;
            end
            y(i) =y(i)/A(i,i);
    end
    k = k +1;
    y
    if norm(y-x,inf) <ep
        break;
    end
    x = y;
end
%   0.131463512038994
%   0.238992233603271
%   0.369041898012517
%   0.430208855026550
%   0.483952590959532