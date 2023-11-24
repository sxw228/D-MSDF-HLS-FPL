# Copyright (C) 2017 Kaan Kara - Systems Group, ETH Zurich

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#*************************************************************************

import numpy as np
from numpy import linalg as la
import time

class ZipML_SGD:
	def __init__(self, on_pynq):
	#def __init__(self, on_pynq, bitstreams_path, ctrl_base, dma_base, dma_buffer_size):
		self.a = None;
		self.b = None;
		self.quantized_a = None;
		self.binarized_b = None;

		self.ka = 8
		self.kx = 16
		self.kb = 16

		self.data_start_index = 0
		self.data_end_index = 0

		self.num_samples = 0;
		self.num_features = 0;
		self.to_int_scaler = 0x00800000
		self.quantization_bits = 0
		self.on_pynq = on_pynq

		self.early_termination_type1_cout = []
		self.early_termination_type2_cout = []
		self.early_termination_type3_cout = []
		self.early_termination_type4_cout = []
		self.early_termination_type5_cout = []

		self.online_early_termination_type1_cout = []
		self.online_early_termination_type2_cout = []
		self.online_early_termination_type3_cout = []
		self.online_early_termination_type4_cout = []
		self.online_early_termination_type5_cout = []


		self.early_termination_count = []
		self.online_early_termination_count = []
		self.total_count = 0
		

	def load_libsvm_data(self, path_to_file, num_samples, num_features):
		if self.on_pynq == 1:
			if self.quantization_bits != 0:
				self.quantization_bits = 0
				self.bitstream = 'floatFSGD.bit'
				ol = self.Overlay(self.bitstreams_path + '/' + self.bitstream)
				ol.download()
				print(self.bitstream + ' is loaded')

			self.num_samples = num_samples
			self.num_features = num_features+1 # Add bias

			if self.num_features%2 == 1:
				self.num_values_one_row = self.num_features+3
			else:
				self.num_values_one_row = self.num_features+2

			print('num_values_one_row: ' + str(self.num_values_one_row))

			self.dma_buffer = self.sgd_dma.get_buf("float *")

			f = open(path_to_file, 'r')
			for i in range(0, self.num_samples):
				self.dma_buffer[int(i*self.num_values_one_row)] = 1
				line = f.readline()
				items = line.split()
				self.dma_buffer[int((i+1)*self.num_values_one_row-2)] = float(items[0])
				for j in range(1, len(items)):
					item = items[j].split(':')
					self.dma_buffer[int( i*self.num_values_one_row + int(item[0]) )] = float(item[1])

			self.total_size = self.num_values_one_row*self.num_samples
			buf = self.sgd_dma.get_cbuf(self.dma_buffer, self.total_size)

			self.ab = np.frombuffer(buf, dtype=np.dtype('f4'), count=self.total_size, offset=0)
			self.ab = np.reshape(self.ab, (self.num_samples, self.num_values_one_row))
			self.a = self.ab[:,0:self.num_features]
			self.b = self.ab[:,self.num_values_one_row-2]

			self.data_start_index = 0
			self.data_end_index = self.total_size
		else:
			if self.quantization_bits != 0:
				self.quantization_bits = 0

			self.num_samples = num_samples
			self.num_features = num_features+1 # Add bias

			self.a = np.zeros((self.num_samples, self.num_features))
			self.b = np.zeros(self.num_samples)

			f = open(path_to_file, 'r')
			for i in range(0, self.num_samples):
				self.a[i, 0] = 1;
				line = f.readline()
				items = line.split()
				self.b[i] = float(items[0])
				for j in range(1, len(items)):
					item = items[j].split(':')
					self.a[i, int(item[0])] = float(item[1])


	def a_normalize(self, to_min1_1, row_or_column):
		if self.quantization_bits != 0:
			raise RuntimeError("Normalization can only be called on non-quantized data!")

		self.a_to_min1_1 = to_min1_1
		if row_or_column == 'r':
			for i in range(0, self.a.shape[0]):
				start = time.time()
				amax = np.amax(self.a[i,1:])
				amin = np.amin(self.a[i,1:])
				arange = amax - amin

				if arange > 0:
					if to_min1_1 == 1:
						self.a[i,1:] = np.subtract( np.divide( np.subtract(self.a[i,1:], amin), arange/2), 1)
					else:
						self.a[i,1:] = np.divide( np.subtract(self.a[i,1:], amin), arange)
		else:
			for j in range(1, self.a.shape[1]):
				amax = np.amax(self.a[:,j])
				amin = np.amin(self.a[:,j])
				arange = amax - amin

				if arange > 0:
					if to_min1_1 == 1:
						self.a[:,j] = np.subtract( np.divide( np.subtract( self.a[:,j], amin ), arange/2), 1)
					else:
						np.divide( np.subtract( self.a[:,j], amin ), arange)

	

	def b_normalize(self, to_min1_1):
		bmax = np.amax(self.b)
		bmin = np.amin(self.b)
		brange = bmax- bmin
		if to_min1_1 == 1:
			for i in range(0, self.b.shape[0]):
				self.b[i] = ((self.b[i]-bmin)/brange)*2.0 - 1.0
		else:
			for i in range(0, self.b.shape[0]):
				self.b[i] = (self.b[i]-bmin)/brange


	def b_binarize(self, value):
		self.binarized_b = np.zeros(self.num_samples)
		for i in range(0, self.b.shape[0]):
			if self.b[i] == value:
				self.binarized_b[i] = 1.0
			else:
				self.binarized_b[i] = -1.0


	def calculate_L2SVM_loss(self, x, cost_pos, cost_neg):

		b_here = self.binarized_b
		loss = 0
		for i in range(0, self.a.shape[0]):
			dot = np.dot(self.a[i,:], x)
			temp = 1 - dot*b_here[i]
			if temp > 0:
				if b_here[i] > 0:
					loss = loss + 0.5*cost_pos*temp*temp
				else:
					loss = loss + 0.5*cost_neg*temp*temp

		norm = la.norm(x)
		loss = loss 

		return loss

	def L2SVM_SGD(self, num_epochs, step_size, cost_pos, cost_neg, step_size_online, online, ka, kx, kb, batch_size):
		
		b_here = self.binarized_b
		x_history = np.zeros((self.num_features, num_epochs))
		x = np.zeros(self.num_features)
		file = open("log_mysvm.txt", 'w')
		for epoch in range(0, num_epochs):
			local_early_termination_count = 0
			local_early_termination_type1_cout = 0
			local_early_termination_type2_cout = 0
			local_early_termination_type3_cout = 0
			local_early_termination_type4_cout = 0
			local_early_termination_type5_cout = 0
			online_local_early_termination_count = 0
			online_local_early_termination_type1_cout = 0
			online_local_early_termination_type2_cout = 0
			online_local_early_termination_type3_cout = 0
			online_local_early_termination_type4_cout = 0
			online_local_early_termination_type5_cout = 0

			for i in range(0, self.a.shape[0]//batch_size):
				x_batch = np.zeros(x.shape)
				for j in range(batch_size):
					self.total_count += 1				
					change_flag = 1	
					dot = np.dot(self.a[i*batch_size+j,:], x)								#点积
					if 1 > b_here[i*batch_size+j] * dot:										#判断是否错分
						if b_here[i*batch_size+j] > 0:
							gradient = cost_pos*(dot - b_here[i*batch_size+j])*self.a[i*batch_size+j,:]
						else:
							gradient = cost_neg*(dot - b_here[i*batch_size+j])*self.a[i*batch_size+j,:]
						if online==0:
							x_batch = x_batch + step_size*gradient
					else:
						change_flag = 0
						local_early_termination_count += 1
						#统计一下发生的位置，在第几个feature上
						a_local = self.a[i*batch_size+j,:]
						b_local = b_here[i*batch_size+j]
						#print(a_local.shape[0])
						shape_1 = int(a_local.shape[0]/5)
						shape_2 = 2*int(a_local.shape[0]/5)
						shape_3 = 3*int(a_local.shape[0]/5)
						shape_4 = 4*int(a_local.shape[0]/5)
						bdot1 = b_local*np.dot(a_local[0:shape_1], x[0:shape_1])
						bdot2 = b_local*np.dot(a_local[shape_1:shape_2], x[shape_1:shape_2])
						bdot3 = b_local*np.dot(a_local[shape_2:shape_3], x[shape_2:shape_3])
						bdot4 = b_local*np.dot(a_local[shape_3:shape_4], x[shape_3:shape_4])
						bdot5 = b_local*np.dot(a_local[shape_4:a_local.shape[0]], x[shape_4:a_local.shape[0]])
						if(bdot1>1):
							local_early_termination_type1_cout +=1
						elif(bdot1+bdot2>1):
							local_early_termination_type2_cout +=1
						elif(bdot1+bdot2+bdot3>1):
							local_early_termination_type3_cout +=1
						elif(bdot1+bdot2+bdot3+bdot4>1):
							local_early_termination_type4_cout +=1
						elif(bdot1+bdot2+bdot3+bdot4+bdot5>1):
							local_early_termination_type5_cout +=1



					#online online online!
					#kb = kx+ka-1
					a_local = self.a[i*batch_size+j,:]/32
					b_local = b_here[i*batch_size+j]/32
					a_online = self.quantize_online_vector(a_local,ka)
					b_online = self.quantize_online_scaler(b_local,kb)
					x_online = self.quantize_online_scaler(x,kx)
					dot_online  = self.quantize_online_scaler(np.dot(a_online, x_online),kb)
					error_online = dot_online - b_online
					
					if 1 > 32*32*(b_online * dot_online):
						#change_flag = 1
						if b_online > 0:
							gradient_temp = cost_pos*error_online*a_online*step_size_online*32
							gradient_online = self.quantize_online_vector(gradient_temp,kx)
						else:
							gradient_temp = cost_neg*error_online*a_online*step_size_online*32
							gradient_online = self.quantize_online_vector(gradient_temp,kx)
						if online==1:
							x = x_online - gradient_online
					else:
						online_local_early_termination_count += 1
						#统计一下发生的位置，在第几个feature上
						a_local = a_online
						b_local = b_online
						#print(a_local.shape[0])
						shape_1 = int(a_local.shape[0]/5)
						shape_2 = 2*int(a_local.shape[0]/5)
						shape_3 = 3*int(a_local.shape[0]/5)
						shape_4 = 4*int(a_local.shape[0]/5)
						bdot1 = b_local*np.dot(a_local[0:shape_1], x_online[0:shape_1])
						bdot2 = b_local*np.dot(a_local[shape_1:shape_2], x_online[shape_1:shape_2])
						bdot3 = b_local*np.dot(a_local[shape_2:shape_3], x_online[shape_2:shape_3])
						bdot4 = b_local*np.dot(a_local[shape_3:shape_4], x_online[shape_3:shape_4])
						bdot5 = b_local*np.dot(a_local[shape_4:a_local.shape[0]], x_online[shape_4:a_local.shape[0]])
						if(32*32*bdot1>1):
							online_local_early_termination_type1_cout +=1
						elif(32*32*(bdot1+bdot2)>1):
							online_local_early_termination_type2_cout +=1
						elif(32*32*(bdot1+bdot2+bdot3)>1):
							online_local_early_termination_type3_cout +=1
						elif(32*32*(bdot1+bdot2+bdot3+bdot4)>1):
							online_local_early_termination_type4_cout +=1
						elif(32*32*(bdot1+bdot2+bdot3+bdot4+bdot5)>1):
							online_local_early_termination_type5_cout +=1
				
					#if epoch ==40 and change_flag==0:
						#if epoch ==10 and i <1:
					#if epoch ==40 and i ==8901 and change_flag==0:
					if epoch ==40 and i*batch_size+j >=8901 and i*batch_size+j <=8932 :
						text = "epoch_index:"+str(epoch)+" sample_index:"+str(i*batch_size+j)+" x:"+str(x)+"\n"
						print(text)
						text = "epoch_index:"+str(epoch)+" sample_index:"+str(i*batch_size+j)+"\na:\n"
						file.write(text)
						self.print_vector(self.a[i*batch_size+j,:],file)
						text = "x:\n"
						file.write(text)
						self.print_vector(x,file)
						#text = str(b_here[i])+"\n"
						#file.write(text)
						text = "dot_result:\n"+str(dot)+"\nb:\n"+str(b_here[i*batch_size+j])+"\ncmp:\n"+str(dot*b_here[i*batch_size+j])+ "\ngradient:\n"
						file.write(text)
						self.print_vector(step_size*gradient,file)
						text = str(b_online)+"\n"
						file.write(text)

						# text = "a_online:\n"
						# file.write(text)
						# self.print_vector(a_online,file)
						# text = "x_online:\n"
						# file.write(text)
						# self.print_vector(x_online,file)
						# text = "dot_result_online:\n"+str(dot_online)+"\n"
						# text += "b_online:\n"+str(b_online)+ "\n"
						# text += "error_online:\n"+ str(error_online) + "\n"
						# text += "gradient_online:\n"
						# file.write(text)
						# self.print_vector(gradient_online,file)
				x = x - x_batch/batch_size

			self.early_termination_count.append(local_early_termination_count)
			self.early_termination_type1_cout.append(local_early_termination_type1_cout)
			self.early_termination_type2_cout.append(local_early_termination_type2_cout)
			self.early_termination_type3_cout.append(local_early_termination_type3_cout)
			self.early_termination_type4_cout.append(local_early_termination_type4_cout)
			self.early_termination_type5_cout.append(local_early_termination_type5_cout)

			self.online_early_termination_count.append(online_local_early_termination_count)
			self.online_early_termination_type1_cout.append(online_local_early_termination_type1_cout)
			self.online_early_termination_type2_cout.append(online_local_early_termination_type2_cout)
			self.online_early_termination_type3_cout.append(online_local_early_termination_type3_cout)
			self.online_early_termination_type4_cout.append(online_local_early_termination_type4_cout)
			self.online_early_termination_type5_cout.append(online_local_early_termination_type5_cout)

			x_history[:,epoch] = x
			
		file.close()
		return x_history

	
	def calculate_LINREG_loss(self, x):
		loss = 0
		for i in range(0, self.a.shape[0]):
			dot = np.dot(self.a[i,:], x)
			temp = dot - self.b[i]
			loss = loss + temp*temp

		norm = la.norm(x)
		loss = loss/(2*self.num_samples)

		return loss

	def print_vector(self,x,file):
		text = ""
		for item in x:
			text += str(item) +" "
		text +="\n"
		file.write(text)

	def quantize_online_vector(self,x,kx):
		'''
		对向量的量化
		'''
		sx = 2**(1-kx)
		item_q = sx * np.rint(x/sx)
		return item_q
	
	def quantize_online_scaler(self,x,kx):
		'''
		对标量的量化
		'''
		sx = 2**(1-kx)
		item_q = sx * np.rint(x/sx)
		return item_q

	def LINREG_SGD(self, num_epochs, step_size, step_size_online, online, ka, kx, kb):
		x_history = np.zeros((self.num_features, num_epochs))
		x = np.zeros(self.num_features)
		file = open("log.txt", 'w')
		for epoch in range(0, num_epochs):
			for i in range(0, self.a.shape[0]):
				dot = np.dot(self.a[i,:], x)
				error = (dot - self.b[i])
				gradient = error*self.a[i,:]
				
				
				#ka = 9
				#kx = 25
				kb = kx+ka-1
				#step_size_online = 1.0/(2**8)
				a_local = self.a[i,:]/32
				b_local = self.b[i]/32
				a_online = self.quantize_online_vector(a_local,ka)
				b_online = self.quantize_online_scaler(b_local,kb)
				x_online = self.quantize_online_scaler(x,kx)
				dot_online  = np.dot(a_online, x_online)
				error_online = dot_online - b_online
				gradient_temp = error_online*a_online*step_size_online*32
				gradient_online = self.quantize_online_vector(gradient_temp,kx)

				if online==1:
					x = x_online - gradient_online
				else:
					x = x - step_size*gradient

				if epoch ==20 and i <50:
					text = "epoch_index:"+str(epoch)+" sample_index:"+str(i)+" x:"+str(x)+"\n"
					print(text)
					#text = "epoch_index:"+str(epoch)+" sample_index:"+str(i)+"\na:\n"
					#file.write(text)
					self.print_vector(self.a[i,:],file)
					#text = "x:\n"
					#file.write(text)
					self.print_vector(x,file)
					#text = "dot_result:\n"+str(dot)+"\nb:\n"+str(self.b[i])+ "\nerror:\n"+ str(error) + "\ngradient:\n"
					#file.write(text)
					#self.print_vector(step_size*gradient,file)
					text = str(b_online)+"\n"
					file.write(text)

					#text = "a_online:\n"
					#file.write(text)
					#self.print_vector(a_online,file)
					#text = "x_online:\n"
					#file.write(text)
					#self.print_vector(x_online,file)
					#text = "dot_result_online:\n"+str(dot_online)+"\n"
					#text += "b_online:\n"+str(b_online)+ "\n"
					#text += "error_online:\n"+ str(error_online) + "\n"
					#text += "gradient_online:\n"
					#file.write(text)
					#self.print_vector(gradient_online,file)
					

			x_history[:,epoch] = x

		return x_history

	#batchsize一直是8了
	def LINREG_SGD_minibatch(self, num_epochs, step_size, step_size_online, online, ka, kx, kb):
		x_history = np.zeros((self.num_features, num_epochs))
		x = np.zeros(self.num_features)
		file = open("log.txt", 'w')
		for epoch in range(0, num_epochs):
			for i in range(0, int(self.a.shape[0]/8)):
				x_batch = np.zeros(self.num_features)
				for j in range(8):
					dot = np.dot(self.a[i*8+j,:], x)
					error = (dot - self.b[i*8+j])
					gradient = error*self.a[i*8+j,:]
					
					a_local = self.a[i*8+j,:]/32
					b_local = self.b[i*8+j]/32
					a_online = self.quantize_online_vector(a_local,ka)
					b_online = self.quantize_online_scaler(b_local,kb)
					x_online = self.quantize_online_scaler(x,kx)
					dot_online  = np.dot(a_online, x_online)
					error_online = dot_online - b_online
					gradient_temp = error_online*a_online*step_size_online*32
					gradient_online = self.quantize_online_vector(gradient_temp,kx)

					if epoch ==20 and i <5:
						text = "epoch_index:"+str(epoch)+" sample_index:"+str(i*8+j)+" x:"+str(i*8+j)+"\n"
						print(text)
						#text = "epoch_index:"+str(epoch)+" sample_index:"+str(i)+"\na:\n"
						#file.write(text)
						self.print_vector(self.a[i*8+j,:],file)
						#text = "x:\n"
						#file.write(text)
						self.print_vector(x,file)
						#text = "dot_result:\n"+str(dot)+"\nb:\n"+str(self.b[i])+ "\nerror:\n"+ str(error) + "\ngradient:\n"
						#file.write(text)
						#self.print_vector(step_size*gradient,file)
						text = str(b_online)+"\n"
						file.write(text)
						#text = "a_online:\n"
						#file.write(text)
						#self.print_vector(a_online,file)
						#text = "x_online:\n"
						#file.write(text)
						#self.print_vector(x_online,file)
						#text = "dot_result_online:\n"+str(dot_online)+"\n"
						#text += "b_online:\n"+str(b_online)+ "\n"
						#text += "error_online:\n"+ str(error_online) + "\n"
						#text += "gradient_online:\n"
						#file.write(text)
						#self.print_vector(gradient_online,file)
					if online==1:
						x_batch = x_batch + gradient_online
					else:
						x_batch = x_batch + step_size*gradient
				x = x-x_batch
			x_history[:,epoch] = x
		
		return x_history
	
	def binary_classification(self, x):
		count_trues = 0
		for i in range(0, self.a.shape[0]):
			matched_class = 0
			dot = np.dot(x, self.a[i,:])
			if (dot > 0 and self.binarized_b[i] == 1.0) or (dot < 0 and self.binarized_b[i] == -1.0):
				count_trues += 1

		return count_trues

	def multi_classification(self, xs, classes):
		matched_class = -1
		count_trues = 0
		for i in range(0, self.a.shape[0]):
			mx = -1000.0
			for c in range(0, len(classes)):
				dot = np.dot(xs[:,c], self.a[i,:])
				if dot > mx:
					mx = dot
					matched_class = classes[c]
			if matched_class == self.b[i]:
				count_trues = count_trues + 1

		return count_trues

	def configure_SGD_FPGA(self, num_epochs, step_size, cost_pos, cost_neg, b_binarize, b_to_binarize):
		if self.on_pynq == 0:
			raise RuntimeError("configure_SGD_FPGA can only be called on PYNQ!")

		# Reserved numbers for configuration
		MAGIC1 = 0x39e904330f1a0df2
		MAGIC2 = 0xb209505f9f560afe
		MAGIC3 = 0x891ebbfdb9d5f766
		MAGIC4 = 0xc049cea2e9f6957d
		MAGIC5 = 0xfe9134a9b660b182
		SEND_CONFIG = 0xabcaabcaabcaabca
		THE_END = 0xabcdabcdabcdabcd

		lambda_shifter = 32
		mini_batch_size = 0
		decrease_step_size = 0

		index64 = int( self.data_end_index/2 )

		self.dma_buffer = self.sgd_dma.get_buf("uint64_t *")
		self.dma_buffer[index64] = THE_END
		index64 += 1

		start_index = index64*2

		self.dma_buffer[index64] = MAGIC1
		index64 += 1
		self.dma_buffer[index64] = ( (b_binarize << 49) + (decrease_step_size << 48) + (mini_batch_size << 32) + lambda_shifter )
		index64 += 1

		self.dma_buffer[index64] = MAGIC2
		index64 += 1
		self.dma_buffer = self.sgd_dma.get_buf("float *")
		if cost_neg == -1 and cost_neg == -1:
			self.dma_buffer[2*index64] = -1;
			self.dma_buffer[2*index64+1] = -1;
		else:
			self.dma_buffer[2*index64] = step_size*cost_neg;
			self.dma_buffer[2*index64+1] = step_size*cost_pos;
		index64 += 1

		self.dma_buffer = self.sgd_dma.get_buf("uint64_t *")
		self.dma_buffer[index64] = MAGIC3
		index64 += 1
		self.dma_buffer = self.sgd_dma.get_buf("float *")
		self.dma_buffer[2*index64] = b_to_binarize
		self.dma_buffer = self.sgd_dma.get_buf("uint32_t *")
		self.dma_buffer[2*index64+1] = self.num_features
		index64 += 1

		self.dma_buffer = self.sgd_dma.get_buf("uint64_t *")
		self.dma_buffer[index64] = MAGIC4
		index64 += 1
		self.dma_buffer = self.sgd_dma.get_buf("uint32_t *")
		self.dma_buffer[2*index64] = self.num_samples
		self.dma_buffer[2*index64+1] = num_epochs
		index64 += 1

		self.dma_buffer = self.sgd_dma.get_buf("uint64_t *")
		self.dma_buffer[index64] = MAGIC5
		index64 += 1
		self.dma_buffer = self.sgd_dma.get_buf("float *")
		self.dma_buffer[2*index64] = step_size
		self.dma_buffer = self.sgd_dma.get_buf("uint32_t *")
		self.dma_buffer[2*index64+1] = self.a_to_min1_1
		index64 += 1

		self.dma_buffer = self.sgd_dma.get_buf("uint64_t *")
		self.dma_buffer[index64] = SEND_CONFIG
		index64 += 1

		end_index = index64*2

		self.sgd_ctrl.write(0x0, 0) # Reset SGD
		time.sleep(0.01)
		self.sgd_ctrl.write(0x0, 1) # Deassert reset
		time.sleep(0.01)

		# Config
		self.sgd_dma.transfer(num_bytes=(end_index-start_index)*4, direction=self._dma.DMA_TO_DEV, offset32=start_index)
		self.sgd_dma.wait(direction=self._dma.DMA_TO_DEV, wait_timeout=5)
		print('Sent')

		self.sgd_dma.transfer(num_bytes=9*4, direction=self._dma.DMA_FROM_DEV, offset32=end_index)
		self.sgd_dma.wait(direction=self._dma.DMA_FROM_DEV, wait_timeout=5)
		print('Config Received')

		self.dma_buffer = self.sgd_dma.get_buf("uint32_t *")

		for i in range(0, 9):
			temp = self.dma_buffer[end_index + i]
			print(hex(temp))

		self.output_offset = end_index+10

	def SGD_FPGA(self, num_epochs):
		if self.on_pynq == 0:
			raise RuntimeError("SGD_FPGA can only be called on PYNQ!")

		print('self.data_start_index: ' + str(self.data_start_index) + ', self.data_end_index: ' + str(self.data_end_index) )

		x_history = np.zeros((self.num_features, num_epochs))

		values_in_one_input_word = 2
		if self.quantization_bits > 0:
			values_in_one_input_word = 64/self.quantization_bits

		accumulation_count = int(self.num_features/values_in_one_input_word) + int(self.num_features%values_in_one_input_word)
		bytes_for_model = int(accumulation_count*values_in_one_input_word*4)
		print('bytes_for_model: ' + str(bytes_for_model))

		for e in range(0, num_epochs):
			transfer_size = ((self.data_end_index - self.data_start_index)+2)*4
			if transfer_size > self.max_dma_transfer_size:
				already_transferred = 0
				while already_transferred < transfer_size:
					if transfer_size - already_transferred > self.max_dma_transfer_size:
						transfer_chunk_size = self.max_dma_transfer_size
					else:
						transfer_chunk_size = transfer_size - already_transferred
					# print('Starting transfer in chunks of size: ' + str(transfer_chunk_size) )
					self.sgd_dma.transfer(num_bytes=transfer_chunk_size, direction=self._dma.DMA_TO_DEV, offset32=self.data_start_index + int(already_transferred/4))
					self.sgd_dma.wait(direction=self._dma.DMA_TO_DEV, wait_timeout=5)
					already_transferred += transfer_chunk_size
			else:
				# print('Starting transfer of size: ' + str(transfer_size) )
				self.sgd_dma.transfer(num_bytes=transfer_size, direction=self._dma.DMA_TO_DEV, offset32=self.data_start_index)
				self.sgd_dma.wait(direction=self._dma.DMA_TO_DEV, wait_timeout=5)
				
			# print('Whole data set is transferred')

			self.sgd_dma.transfer(num_bytes=bytes_for_model, direction=self._dma.DMA_FROM_DEV, offset32=self.output_offset)
			self.sgd_dma.wait(direction=self._dma.DMA_FROM_DEV, wait_timeout=5)

			self.dma_buffer = self.sgd_dma.get_buf("int32_t *")
			for j in range(0, self.num_features):
				temp = self.dma_buffer[self.output_offset + j]
				# print('temp: ' + hex(temp))
				x_history[j,e] = float(temp)/self.to_int_scaler

		return x_history

	def loopback(self):
		ol = self.Overlay(self.bitstreams_path + '/qFSGD4.bit')
		ol.download()
		print('floatFSGD.bit is loaded')

		self.sgd_ctrl.write(0x0, 0) # Reset SGD
		time.sleep(0.01)
		self.sgd_ctrl.write(0x0, 1) # Deassert reset
		time.sleep(0.01)

		LOOPBACK = 0xabababababababab
		UNLOOPBACK = 0xbabababababababa

		start_index = 0

		index64 = int( start_index/2 )

		self.dma_buffer = self.sgd_dma.get_buf("uint64_t *")
		self.dma_buffer[index64] = LOOPBACK
		index64 += 1
		self.dma_buffer[index64] = 0x123456789ABCDEF1
		index64 += 1
		self.dma_buffer[index64] = UNLOOPBACK
		index64 += 1

		end_index = 2*index64

		
		self.sgd_dma.transfer(num_bytes=8, direction=self._dma.DMA_TO_DEV, offset32=0)
		self.sgd_dma.wait(direction=self._dma.DMA_TO_DEV, wait_timeout=5)

		self.sgd_dma.transfer(num_bytes=8, direction=self._dma.DMA_TO_DEV, offset32=2)
		self.sgd_dma.wait(direction=self._dma.DMA_TO_DEV, wait_timeout=5)

		self.sgd_dma.transfer(num_bytes=8, direction=self._dma.DMA_TO_DEV, offset32=4)
		self.sgd_dma.wait(direction=self._dma.DMA_TO_DEV, wait_timeout=5)

		self.sgd_dma.transfer(num_bytes=4, direction=self._dma.DMA_FROM_DEV, offset32=6)
		self.sgd_dma.wait(direction=self._dma.DMA_FROM_DEV, wait_timeout=5)

		self.dma_buffer = self.sgd_dma.get_buf("uint32_t *")

		for i in range(start_index, end_index+1):
			print(hex(self.dma_buffer[i]))
