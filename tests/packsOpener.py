import pytest
import asyncio

from types import SimpleNamespace

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.definitions.error_codes import StarknetErrorCode
from starkware.starknet.compiler.compile import get_selector_from_name

from utils.Signer import Signer
from utils.misc import deploy_proxy, assert_revert, str_to_felt, assert_event_emmited
from utils.TransactionSender import TransactionSender


VERSION = str_to_felt('0.1.0')


@pytest.mark.asyncio
async def test_take_and_open_pack(ctx_factory):
  ctx = ctx_factory()
  manager_sender = TransactionSender(ctx.accounts.manager)
  core_owner_sender = TransactionSender(ctx.accounts.core_owner)

  assert 1 == 1

  # # should revert with the wrong signer
  # await assert_revert(
  #   sender.send_transaction([(dapp.contract_address, 'set_number', [47])], wrong_signer),
  #   'Account: invalid signer signature'
  # )
  #
  # # should call the dapp
  # assert (await dapp.get_number(account.contract_address).call()).result.number == 0
  # await sender.send_transaction([(dapp.contract_address, 'set_number', [47])], signer)
  # assert (await dapp.get_number(account.contract_address).call()).result.number == 47
