import pytest
import asyncio

from types import SimpleNamespace

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.definitions.error_codes import StarknetErrorCode

from utils.misc import deploy_proxy, assert_revert, uint, assert_event_emmited, str_to_felt, to_starknet_args, declare
from utils.TransactionSender import TransactionSender

from conftest import cardModel1, cardModel2, cardModel3, metadata


VERSION = str_to_felt('0.1.0')


@pytest.mark.asyncio
async def test_take_and_return_pack(ctx_factory):
  ctx = ctx_factory()
  manager_sender = TransactionSender(ctx.manager)
  owner_sender = TransactionSender(ctx.owner)
  rando1_sender = TransactionSender(ctx.rando1)

  # mint packs
  await owner_sender.send_transaction([
    (
      ctx.rules_tokens.contract_address,
      'mintPack',
      [*uint(1), ctx.rando1.contract_address, 2, 1],
    ),
  ], ctx.signers['owner'])

  await rando1_sender.send_transaction([
    (
      ctx.rules_tokens.contract_address,
      'approve',
      [ctx.packs_opener.contract_address, *uint(1), *uint(2)],
    ),
  ], ctx.signers['rando1'])

  await manager_sender.send_transaction([
    (ctx.packs_opener.contract_address, 'takePackFrom', [ctx.rando1.contract_address, *uint(1)]),
    (ctx.packs_opener.contract_address, 'takePackFrom', [ctx.rando1.contract_address, *uint(1)]),
  ], ctx.signers['manager']),

  assert (await ctx.packs_opener.balanceOf(ctx.rando1.contract_address, uint(1)).call()).result.balance == uint(2)
  assert (await ctx.rules_tokens.balanceOf(ctx.rando1.contract_address, uint(1)).call()).result.balance == uint(0)

  await owner_sender.send_transaction([
    (ctx.packs_opener.contract_address, 'returnPack', [ctx.rando1.contract_address, *uint(1)]),
  ], ctx.signers['owner']),

  assert (await ctx.packs_opener.balanceOf(ctx.rando1.contract_address, uint(1)).call()).result.balance == uint(0)
  assert (await ctx.rules_tokens.balanceOf(ctx.rando1.contract_address, uint(1)).call()).result.balance == uint(2)
