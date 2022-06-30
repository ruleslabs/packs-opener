%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

# Libraries

from packsOpener.library import PacksOpener

from periphery.introspection.ERC165 import ERC165

from ruleslabs.lib.Ownable_base import (
  Ownable_get_owner,

  Ownable_initializer,
  Ownable_only_owner,
  Ownable_transfer_ownership,
)

from libs.roles.opener import (
  Opener_role,

  Opener_initializer,
  Opener_only_opener,
  Opener_grant,
  Opener_revoke,
)

from ruleslabs.lib.roles.AccessControl_base import (
  AccessControl_has_role,
  AccessControl_roles_count,
  AccessControl_role_member,

  AccessControl_initializer,
)

#
# Initializer
#

@external
func initialize{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(owner: felt, _rules_tokens_address: felt):
  Ownable_initializer(owner)
  AccessControl_initializer(owner)
  Opener_initializer(owner)

  PacksOpener.initializer(owner, _rules_tokens_address)
  return ()
end

#
# Getters
#

# Roles

@view
func OPENER_ROLE{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (role: felt):
  let (role) = Opener_role()
  return (role)
end

@view
func owner{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (owner: felt):
  let (owner) = Ownable_get_owner()
  return (owner)
end

@view
func getRoleMember{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt, index: felt) -> (account: felt):
  let (account) = AccessControl_role_member(role, index)
  return (account)
end

@view
func getRoleMemberCount{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt) -> (count: felt):
  let (count) = AccessControl_roles_count(role)
  return (count)
end

@view
func get_version() -> (version: felt):
  let (version) = PacksOpener.get_version()
  return (version)
end

@view
func hasRole{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(role: felt, account: felt) -> (has_role: felt):
  let (has_role) = AccessControl_has_role(role, account)
  return (has_role)
end

@view
func supportsInterface{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  } (interfaceId: felt) -> (success: felt):
  let (success) = ERC165.supports_interface(interfaceId)
  return (success)
end

# Other contracts

@view
func rulesTokens{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (address: felt):
  let (address) = PacksOpener.rules_tokens()
  return (address)
end

#
# Setters
#

# Roles

@external
func addOpener{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt):
  Opener_grant(account)
  return ()
end

@external
func revokeOpener{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt):
  Opener_revoke(account)
  return ()
end

@external
func upgrade{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(implementation: felt):
  Ownable_only_owner()
  PacksOpener.upgrade(implementation)
  return ()
end

#
# Business logic
#

@external
func takePackFrom{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(packId: Uint256, _from: felt):
  Opener_only_opener()
  PacksOpener.take_pack_from(packId, _from)
  return ()
end

@external
func openPackTo{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(packId: Uint256, to: felt):
  Opener_only_opener()
  PacksOpener.open_pack_to(packId, to)
  return ()
end

#
# ERC1155 Hooks
#

@view
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
  let (selector) = PacksOpener.on_ERC1155_received(
    operator,
    _from,
    id,
    value,
    data_len,
    data
  )
  return (selector)
end

@view
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
  let (selector) = PacksOpener.on_ERC1155_batch_received(
    operator,
    _from,
    ids_len,
    ids,
    values_len,
    values,
    data_len,
    data
  )
  return (selector)
end

# Ownership

@external
func transferOwnership{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(new_owner: felt) -> (new_owner: felt):
  Ownable_transfer_ownership(new_owner)
  return (new_owner)
end

@external
func renounceOwnership{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }():
  Ownable_transfer_ownership(0)
  return ()
end
