## 文件结构
-EDA TOOLS  
	Lana's tools  
	C++ model  
	Our MSDF backend flow  
	Other scripts  
-RTL DESIGN  
-DOCUMENTS  
	Paper  
	Visio files  
	PPT  

## 整体流程
1.处理cpp放在 EDA_TOOLS/DHLS/elastic#-circuit/examples里,在filelist.lst里添加文件名  
2.运行compile_test.sh,在_build文件夹里得到  
(1).ll后缀:llvm ir文件  
(2).dot后缀:拓扑图描述  
(3).png后缀:可视化  
3.在online_verifer里指定.dot文件路径,运行dot2hdl,得到.v后缀文件,这是最终生成的rtl  
4.(TODO)生成testbench  
