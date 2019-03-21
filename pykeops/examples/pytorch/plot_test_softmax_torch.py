"""
SoftMax reduction
===========================
"""

###############################################################################
# Using the :mod:`pykeops.torch.Genred` API,
# we show how to perform a computation specified through:
#  
# * Its **inputs**: 
#     
#     - :math:`x`, an array of size :math:`M\times 3` made up of :math:`M` vectors in :math:`\mathbb R^3`,
#     - :math:`y`, an array of size :math:`N\times 3` made up of :math:`N` vectors in :math:`\mathbb R^3`,
#     - :math:`b`, an array of size :math:`N\times 2` made up of :math:`N` vectors in :math:`\mathbb R^2`.
# 
# * Its **output**:
#     
#     - :math:`c`, an array of size :math:`M\times 2` made up of
#       :math:`M` vectors in :math:`\mathbb R^2` such that
#       
#       .. math::
#         
#           c_i = \frac{\sum_j \exp(K(x_i,y_j))\,\cdot\,b_j }{\sum_j \exp(K(x_i,y_j))},
#       
#       with :math:`K(x_i,y_j) = \|x_i-y_j\|^2`.
#

###############################################################################
# Setup
# ----------------
#
# Standard imports:

import time
import torch
from pykeops.torch import Genred
    
###############################################################################
# Define our dataset:
#

M = 500  # Number of "i" points
N = 400  # Number of "j" points
D = 3    # Dimension of the ambient space
Dv = 2   # Dimension of the vectors

x = 2*torch.randn(M,D)
y = 2*torch.randn(N,D)
b = torch.rand(N,Dv)


###############################################################################
# KeOps kernel
# ---------------
# 
# Create a new generic routine using the :func:`pykeops.numpy.Genred`
# constructor:

formula = 'SqDist(x,y)'
formula_weights = 'b'
aliases = ['x = Vx('+str(D)+')',   # First arg:  i-variable of size D
           'y = Vy('+str(D)+')',   # Second arg: j-variable of size D
           'b = Vy('+str(Dv)+')']  # Third arg:  j-variable of size Dv

softmax_op = Genred(formula, aliases, reduction_op='SoftMax', axis=1, 
                    formula2=formula_weights)

# Dummy first call to warmup the GPU and get accurate timings:
_ = softmax_op(x, y, b)

###############################################################################
# Use our new function on arbitrary Numpy arrays:
#

start = time.time()
c = softmax_op(x, y, b)
print("Timing (KeOps implementation): ",round(time.time()-start,5),"s")

# compare with direct implementation
start = time.time()
cc  = torch.sum( ( x[:,None,:] - y[None,:,:] ) ** 2, axis=2)
cc -= torch.max(cc,dim=1)[0][:,None] # subtract the max for robustness
cc  = torch.exp(cc)@b / torch.sum(torch.exp(cc),dim=1)[:,None]
print("Timing (Numpy implementation): ",round(time.time()-start,5),"s")

print("Relative error : ", (torch.norm(c - cc) / torch.norm(c)).item())

