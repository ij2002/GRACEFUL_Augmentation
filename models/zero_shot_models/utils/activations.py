from torch import nn
from torch.nn import LeakyReLU, CELU, SELU
from torch.nn import functional as F

LeakyReLU
CELU
SELU


class GELU(nn.Module):
    def __init__(self, inplace: bool = False):
        #? Accepted and ignored: F.gelu has no in-place form, but every caller
        #? (DynamicLayer.get_act, SemanticGraphAugmentor) passes the flag.
        super().__init__()

    def forward(self, input):
        return F.gelu(input)


#? Single source of truth for the --activation choices: every name here must be
#? resolvable via activations.__dict__ (see DynamicLayer.get_act / FcOutModel).
ACTIVATION_CLASS_NAMES = ('LeakyReLU', 'CELU', 'SELU', 'GELU')
DEFAULT_ACTIVATION_CLASS_NAME = 'LeakyReLU'
