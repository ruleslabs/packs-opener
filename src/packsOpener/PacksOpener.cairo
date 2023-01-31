%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256

from ruleslabs.models.metadata import Metadata
from ruleslabs.models.card import Card

// Libraries

from packsOpener.library import PacksOpener

from openzeppelin.introspection.erc165.library import ERC165

from ruleslabs.lib.Ownable_base import (
  Ownable_get_owner,
  Ownable_initializer,
  Ownable_only_owner,
  Ownable_transfer_ownership,
)

from libs.roles.manager import (
  Manager_role,
  Manager_initializer,
  Manager_only_manager,
  Manager_grant,
  Manager_revoke,
)

from ruleslabs.lib.roles.AccessControl_base import (
  AccessControl_has_role,
  AccessControl_roles_count,
  AccessControl_role_member,
  AccessControl_initializer,
)

//
// Initializer
//

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt, _rules_tokens_address: felt
) {
  Ownable_initializer(owner);
  AccessControl_initializer(owner);
  Manager_initializer(owner);

  PacksOpener.initializer(owner, _rules_tokens_address);
  return ();
}

//
// Getters
//

// Roles

@view
func OPENER_ROLE{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  role: felt
) {
  let (role) = Manager_role();
  return (role,);
}

@view
func owner{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (owner: felt) {
  let (owner) = Ownable_get_owner();
  return (owner,);
}

@view
func getRoleMember{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  role: felt, index: felt
) -> (account: felt) {
  let (account) = AccessControl_role_member(role, index);
  return (account,);
}

@view
func getRoleMemberCount{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  role: felt
) -> (count: felt) {
  let (count) = AccessControl_roles_count(role);
  return (count,);
}

@view
func get_version() -> (version: felt) {
  let (version) = PacksOpener.get_version();
  return (version,);
}

@view
func hasRole{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  role: felt, account: felt
) -> (has_role: felt) {
  let (has_role) = AccessControl_has_role(role, account);
  return (has_role,);
}

@view
func supportsInterface{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  interfaceId: felt
) -> (success: felt) {
  let (success) = ERC165.supports_interface(interfaceId);
  return (success,);
}

// Other contracts

@view
func rulesTokens{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
  address: felt
) {
  let (address) = PacksOpener.rules_tokens();
  return (address,);
}

// Balances

@view
func balanceOf{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  account: felt, token_id: Uint256
) -> (balance: Uint256) {
  let (balance) = PacksOpener.balance_of(account, token_id);
  return (balance,);
}

//
// Setters
//

// Roles

@external
func addManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Manager_grant(account);
  return ();
}

@external
func revokeManager{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) {
  Manager_revoke(account);
  return ();
}

@external
func upgrade{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  implementation: felt
) {
  Ownable_only_owner();
  PacksOpener.upgrade(implementation);
  return ();
}

//
// Business logic
//

@external
func takePackFrom{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  _from: felt, packId: Uint256
) {
  Manager_only_manager();
  PacksOpener.take_pack_from(_from, packId);
  return ();
}

@external
func returnPack{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  owner: felt, packId: Uint256
) {
  Ownable_only_owner();
  PacksOpener.return_pack(owner, packId);
  return ();
}

//
// ERC1155 Hooks
//

@view
func onERC1155Received{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt, _from: felt, id: Uint256, value: Uint256, data_len: felt, data: felt*
) -> (selector: felt) {
  let (selector) = PacksOpener.on_ERC1155_received(operator, _from, id, value, data_len, data);
  return (selector,);
}

@view
func onERC1155BatchReceived{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  operator: felt,
  _from: felt,
  ids_len: felt,
  ids: felt*,
  values_len: felt,
  values: felt*,
  data_len: felt,
  data: felt*,
) -> (selector: felt) {
  let (selector) = PacksOpener.on_ERC1155_batch_received(
    operator, _from, ids_len, ids, values_len, values, data_len, data
  );
  return (selector,);
}

// Ownership

@external
func transferOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
  new_owner: felt
) -> (new_owner: felt) {
  Ownable_transfer_ownership(new_owner);
  return (new_owner,);
}

@external
func renounceOwnership{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
  Ownable_transfer_ownership(0);
  return ();
}
