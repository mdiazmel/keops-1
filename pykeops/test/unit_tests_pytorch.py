import os.path
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)) + (os.path.sep + '..')*2)

import unittest
import itertools
import numpy as np

from pykeops.numpy.utils import np_kernel, grad_np_kernel, differences, squared_distances
from pykeops.numpy.convolutions.radial_kernels import radial_kernels_conv
from pykeops.numpy.convolutions.radial_kernels_grad1 import radial_kernels_grad1conv

from pykeops import torch_found

@unittest.skipIf(not torch_found,"Pytorch was not found on your system. Skip tests.")
class PytorchUnitTestCase(unittest.TestCase):

    N    = int(6)
    M    = int(10)
    D = int(3)
    E  = int(3)

    a = np.random.rand(N,E).astype('float32')
    x = np.random.rand(N,D).astype('float32')
    y = np.random.rand(M,D).astype('float32')
    f = np.random.rand(M,1).astype('float32')
    b = np.random.rand(M,E).astype('float32')
    sigma = np.array([0.4]).astype('float32')

    import torch
    from torch.autograd import Variable

    use_cuda = torch.cuda.is_available()
    dtype    = torch.cuda.FloatTensor if use_cuda else torch.FloatTensor

    ac = Variable(torch.from_numpy(a.copy()).type(dtype), requires_grad=True).type(dtype)
    xc = Variable(torch.from_numpy(x.copy()).type(dtype), requires_grad=True).type(dtype)
    yc = Variable(torch.from_numpy(y.copy()).type(dtype), requires_grad=True).type(dtype)
    fc = Variable(torch.from_numpy(f.copy()).type(dtype), requires_grad=True).type(dtype)
    bc = Variable(torch.from_numpy(b.copy()).type(dtype), requires_grad=True).type(dtype)
    sigmac = torch.autograd.Variable(torch.from_numpy(sigma.copy()).type(dtype), requires_grad=False).type(dtype)

#--------------------------------------------------------------------------------------
    def test_conv_kernels_feature(self):
#--------------------------------------------------------------------------------------
        from pykeops.torch.kernels import Kernel, kernel_product
        mode = "sum"
        params = {
            "gamma"   : 1./self.sigmac**2,
        }
        for k,b in itertools.product(["gaussian", "laplacian", "cauchy", "inverse_multiquadric"],['auto','GPU_1D','GPU_2D','pytorch']):
            with self.subTest(k=k,b=b):
                params["id"] = Kernel(k+"(x,y)")
                params["backend"] = b
                # Call cuda kernel
                gamma = kernel_product( self.xc,self.yc,self.bc, params, mode=mode).cpu()

                # Numpy version    
                gamma_py = np.matmul(np_kernel(self.x, self.y,self.sigma,kernel=k), self.b)

                # compare output
                self.assertTrue( np.allclose(gamma.data.numpy(), gamma_py))

#--------------------------------------------------------------------------------------
    def test_grad1conv_kernels_feature(self):
#--------------------------------------------------------------------------------------
        import torch
        from torch.autograd import grad
        from pykeops.torch.kernels import Kernel, kernel_product
        mode = "sum"
        params = {
            "gamma"   : 1./self.sigmac**2,
        }

        for k,b in itertools.product(["gaussian", "laplacian", "cauchy", "inverse_multiquadric"],['auto','GPU_1D','GPU_2D','pytorch']):
            with self.subTest(k=k,b=b):
                params["id"] = Kernel(k+"(x,y)")
                params["backend"] = b

                # Call cuda kernel
                aKxy_b = torch.dot(self.ac.view(-1), kernel_product( self.xc,self.yc,self.bc, params, mode=mode).view(-1))
                gamma_keops   = torch.autograd.grad(aKxy_b, self.xc, create_graph=False)[0].cpu()

                # Numpy version
                A = differences(self.x, self.y) * grad_np_kernel(self.x,self.y,self.sigma,kernel=k)
                gamma_py = 2*(np.sum( self.a * (np.matmul(A,self.b)),axis=2) ).T

                # compare output
                self.assertTrue( np.allclose(gamma_keops.cpu().data.numpy(), gamma_py , atol=1e-6))

#--------------------------------------------------------------------------------------
    def test_generic_syntax(self):
#--------------------------------------------------------------------------------------
        from pykeops.torch.kernels import Kernel
        from pykeops.torch.generic_sum import GenericSum
        aliases = ["p=Pm(0,1)","a=Vy(1,1)","x=Vx(2,3)","y=Vy(3,3)"]
        formula = "Square(p-a)*Exp(x+y)"
        signature   =   [ (3, 0), (1, 2), (1, 1), (3, 0), (3, 1) ]
        sum_index = 0       # 0 means summation over j, 1 means over i 

        for b in ['auto','GPU_1D','GPU_2D','GPU']:
            with self.subTest(b=b):

                # Call cuda kernel
                gamma_keops = GenericSum.apply(b,aliases,formula,signature,sum_index,self.sigmac,self.fc,self.xc,self.yc)

                # Numpy version
                gamma_py = np.sum((self.sigma - self.f)**2 *np.exp( (self.y.T[:,:,np.newaxis] + self.x.T[:,np.newaxis,:])),axis=1).T

                # compare output
                self.assertTrue( np.allclose(gamma_keops.cpu().data.numpy(), gamma_py , atol=1e-6))


if __name__ == '__main__':
    """
    run tests
    """
    unittest.main()
