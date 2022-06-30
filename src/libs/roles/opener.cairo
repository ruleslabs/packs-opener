%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from ruleslabs.lib.roles.AccessControl_base import (
  AccessControl_has_role,

  AccessControl_grant_role,
  AccessControl_revoke_role,
  _grant_role
)

# Constants

const OPENER_ROLE = 0x44F50454E45525F524F4C45 # "OPENER_ROLE"

#
# Constructor
#

func Opener_initializer{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(admin: felt):
  _grant_role(OPENER_ROLE, admin)
  return ()
end

#
# Getters
#

func Opener_role{}() -> (role: felt):
  return (OPENER_ROLE)
end

#
# Externals
#

func Opener_only_opener{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }():
  let (caller) = get_caller_address()
  let (has_role) = AccessControl_has_role(OPENER_ROLE, caller)
  with_attr error_message("AccessControl: only openers are authorized to perform this action"):
    assert has_role = TRUE
  end

  return ()
end

func Opener_grant{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(account: felt):
  AccessControl_grant_role(OPENER_ROLE, account)
  return ()
end

func Opener_revoke{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt) -> ():
  AccessControl_revoke_role(OPENER_ROLE, account)
  return ()
end
