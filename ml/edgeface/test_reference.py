import unittest
import numpy as np
from reference import TEMPLATE, align_tensor, assert_parity

class ReferenceTest(unittest.TestCase):
    def test_identity_rgb_contract(self):
        rgb=np.zeros((112,112,3),dtype=np.uint8); rgb[:,:,0]=255
        out=align_tensor(rgb,TEMPLATE)
        np.testing.assert_allclose(out[0,:,56,56],[1,-1,-1],atol=1e-6)
    def test_parity_catches_changed_channels(self):
        with self.assertRaises(AssertionError): assert_parity([1,0,0],[0,1,0])
    def test_invalid_outputs_rejected(self):
        for bad in ([0,0],[float('nan'),1],[float('inf'),1]):
            with self.assertRaises(ValueError): assert_parity([1,1],bad)
    def test_degenerate_landmarks_rejected(self):
        with self.assertRaises(ValueError): align_tensor(np.zeros((112,112,3)),np.zeros((5,2)))

if __name__=='__main__': unittest.main()
