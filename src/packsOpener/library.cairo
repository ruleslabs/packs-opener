%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import (
  call_contract, get_contract_address
)
#
# Libraries
#

from openzeppelin.introspection.ERC165 import (
  ERC165_register_interface
)

from ruleslabs.utils.constants import IERC1155_ACCEPTED_ID, IERC1155_RECEIVER_ID
from periphery.proxy.library import Proxy

#
# Constants
#

const VERSION = '0.1.0'

#
# Storage
#

@storage_var
func contract_initialized() -> (exists: felt):
end

namespace PacksOpener:

  #
  # Initializer
  #

  func initializer{
      syscall_ptr : felt*,
      pedersen_ptr : HashBuiltin*,
      range_check_ptr
    }(owner: felt):
    # assert not already initialized
    let (initialized) = contract_initialized.read()
    with_attr error_message("PacksOpener: contract already initialized"):
        assert initialized = FALSE
    end
    contract_initialized.write(TRUE)

    ERC165_register_interface(IERC1155_RECEIVER_ID)
    return ()
  end

  #
  # Getters
  #

  func get_version() -> (version: felt):
    return (version=VERSION)
  end

  #
  # Setters
  #

  func upgrade{
      syscall_ptr : felt*,
      pedersen_ptr : HashBuiltin*,
      range_check_ptr
    }(implementation: felt):
    # make sure the target is not null
    with_attr error_message("PacksOpener: new implementation cannot be null"):
      assert_not_zero(implementation)
    end

    # change implementation
    Proxy.set_implementation(implementation)
    return ()
  end

  #
  # Business logic
  #

  func takePackFrom{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(packId: Uint256, _from: felt):
    return ()
  end

  func openPackTo{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(packId: Uint256, to: felt):
    return ()
  end

  #
  # ERC1155 Hooks
  #

  func onERC1155Received{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(
      operator: felt,
      _from: felt,
      id: Uint256,
      value: Uint256,
      data_len: felt,
      data: felt*
    ) -> (selector: felt):
    # only called via takePackFrom
    let (self) = get_contract_address()
    if operator == self:
      return (0)
    end

    return (IERC1155_ACCEPTED_ID)
  end

  func onERC1155BatchReceived{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(
      operator: felt,
      _from: felt,
      ids_len: felt,
      ids: felt*,
      values_len: felt,
      values: felt*,
      data_len: felt,
      data: felt*
    ) -> (selector: felt):
    return (0)
  end
end
