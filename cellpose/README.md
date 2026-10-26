# Scripts
run_Cellpose-SAM.ipynb to run model on experimental dataset. make sure to select the correct model, load images together or individually on GPU and select correct thresholds before running.

train_Cellpose-SAM.ipynb: script for training model, and also testing with evaluation metrics and visualization of ground truth and predicted masks.

# Cellpose installation guidelines.

Installation Cellpose-SAM steps, taken from: https://github.com/MouseLand/cellpose.git.

In windows powershell: 

	1. conda create --name cellposesam python=3.12
	2. conda activate cellpose
	3. python -m pip install cellpose[gui]
	4. python -m pip install notebook
	5. python -m pip install matplotlib

I Tried:
Python -m cellpose

(cellposesam) PS C:\Users\20223228> python -m cellpose
[GUI INFO] : WRITING LOG OUTPUT TO C:\Users\20223228\.cellpose\run.log

cellpose version:       4.2.1.1
platform:               win32
python version:         3.12.14
torch version:          2.14.0+cpu
2026-09-23 16:22:41,549 [io INFO] WRITING LOG OUTPUT TO C:\Users\20223228\.cellpose\run.log
2026-09-23 16:22:41,549 [io INFO]
cellpose version:       4.2.1.1
platform:               win32
python version:         3.12.14
torch version:          2.14.0+cpu
2026-09-23 16:22:41,870 [core INFO] Neither TORCH CUDA nor MPS version not installed/working.

GUI was not enabled (also not checked in GUI). To enable use of GPU:

		1. pip uninstall torch
		2. pip3 install torch torchvision --index-url https://download.pytorch.org/whl/cu126

