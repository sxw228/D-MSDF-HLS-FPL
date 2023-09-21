## 文件结构
* EDA_TOOLS  
** D-MSDF-HLS-master                  Lana's tools  
** online_verifier                    C++ model  
** online_verifier_py                 Python model with GMP  
** Parser                             The tool used in FPL  
** Other scripts                      TODO  
* RTL                                 RTL DESIGN  
* DOCUMENTS  
** Paper  
** Visio files  
** PPT  

## 整体流程
### linux上的流程，假设安装路径是PATH：/home/sxw228/Desktop/msdf/dynamatic-master/
1.待处理sgd.cpp放在 PATH/elastic-circuit/examples里,在PATH/elastic-circuit/examples/filelist.lst里添加文件名  
2.在PATH/elastic-circuit/examples打开终端命令行，运行./compile_test.sh,在_build文件夹里得到sgd文件夹  
(1).ll后缀:llvm ir文件  
(2).dot后缀:拓扑图描述  
(3).png后缀:可视化  

### windows上的流程
3.在EDA_TOOLS/online_verifer里指定.dot文件路径,运行dot2hdl,得到.v后缀文件,这是最终生成的rtl  
```
hdl_writer hdl_writer;
parse_dot("F:/msdf/matlab/jacobi_5");
check_netlist();
hdl_writer.write_hdl("F:/msdf/matlab/jacobi_5", 0);
```
4.(TODO)生成testbench  

### FPL实验
1. (TODO)jupyter notebook 与硬件结果一致的软件仿真
2. (TODO)画图脚本 
