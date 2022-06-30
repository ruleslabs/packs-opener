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

# Interfaces

from ruleslabs.contracts.RulesTokens.IRulesTokens import IRulesTokens

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

# Other contracts

@storage_var
func rules_tokens_address_storage() -> (rules_cards_address: felt):
end

# Balances

@storage_var
func balances_storage(owner: felt, pack_id: Uint256) -> (balance: felt):
end

namespace PacksOpener:

  #
  # Initializer
  #

  func initializer{
      syscall_ptr : felt*,
      pedersen_ptr : HashBuiltin*,
      range_check_ptr
    }(owner: felt, _rules_tokens_address: felt):
    # assert not already initialized
    let (initialized) = contract_initialized.read()
    with_attr error_message("PacksOpener: contract already initialized"):
        assert initialized = FALSE
    end
    contract_initialized.write(TRUE)

    # ERC165 interfaces
    ERC165_register_interface(IERC1155_RECEIVER_ID)

    # other contracts
    rules_tokens_address_storage.write(_rules_tokens_address)

    return ()
  end

  #
  # Getters
  #

  func get_version() -> (version: felt):
    return (version=VERSION)
  end

  # Other contracts

  func rules_tokens{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }() -> (address: felt):
    let (address) = rules_tokens_address_storage.read()
    return (address)
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

  func take_pack_from{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(pack_id: Uint256, _from: felt):
    alloc_locals

    # assert pack exists
    with_attr error_message("PacksOpener: Pack does not exist"):
      assert pack_id.low * pack_id.high = 0
    end

    # transfer pack
    let (self) = get_contract_address()
    let (rules_tokens_address) = rules_tokens_address_storage.read()

    let data = cast(0, felt*)
    IRulesTokens.safeTransferFrom(
      rules_tokens_address,
      _from=_from,
      to=self,
      token_id=pack_id,
      amount=Uint256(1, 0),
      data_len=0,
      data=data
    )

    # Increase balance
    let (balance) = balances_storage.read(owner=_from, pack_id=pack_id)
    balances_storage.write(owner=_from, pack_id=pack_id, value=balance + 1)

    return ()
  end

  func open_pack_to{
      syscall_ptr: felt*,
      pedersen_ptr: HashBuiltin*,
      range_check_ptr
    }(pack_id: Uint256, to: felt):
    return ()
  end

  #
  # ERC1155 Hooks
  #

  func on_ERC1155_received{
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

  func on_ERC1155_batch_received{
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
