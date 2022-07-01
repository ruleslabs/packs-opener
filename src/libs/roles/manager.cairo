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

const MANAGER_ROLE = 0x4D414E414745525F524F4C45 # "MANAGER_ROLE"

#
# Constructor
#

func Manager_initializer{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(admin: felt):
  _grant_role(MANAGER_ROLE, admin)
  return ()
end

#
# Getters
#

func Manager_role{}() -> (role: felt):
  return (MANAGER_ROLE)
end

#
# Externals
#

func Manager_only_manager{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }():
  let (caller) = get_caller_address()
  let (has_role) = AccessControl_has_role(MANAGER_ROLE, caller)
  with_attr error_message("AccessControl: only managers are authorized to perform this action"):
    assert has_role = TRUE
  end

  return ()
end

func Manager_grant{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr
  }(account: felt):
  AccessControl_grant_role(MANAGER_ROLE, account)
  return ()
end

func Manager_revoke{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(account: felt) -> ():
  AccessControl_revoke_role(MANAGER_ROLE, account)
  return ()
end
