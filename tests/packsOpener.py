import pytest
import asyncio

from types import SimpleNamespace

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.definitions.error_codes import StarknetErrorCode

from utils.misc import deploy_proxy, assert_revert, uint, assert_event_emmited, str_to_felt
from utils.TransactionSender import TransactionSender


VERSION = str_to_felt('0.1.0')


@pytest.mark.asyncio
async def test_take_pack(ctx_factory):
  ctx = ctx_factory()
  manager_sender = TransactionSender(ctx.manager, ctx.signers['manager'])
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])

  # mint packs
  await owner_sender.send_transaction([
    (
      ctx.rules_tokens.contract_address,
      'mintPack',
      [*uint(1), ctx.rando1.contract_address, 2, ctx.packs_opener.contract_address],
    ),
  ])

  await manager_sender.send_transaction([
    (ctx.packs_opener.contract_address, 'takePackFrom', [ctx.rando1.contract_address, *uint(1)]),
    (ctx.packs_opener.contract_address, 'takePackFrom', [ctx.rando1.contract_address, *uint(1)]),
  ]),

  assert (await ctx.packs_opener.balanceOf(ctx.rando1.contract_address, uint(1)).call()).result.balance == uint(2)
  assert (await ctx.rules_tokens.balanceOf(ctx.rando1.contract_address, uint(1)).call()).result.balance == uint(0)


@pytest.mark.asyncio
async def test_invlid_take_pack(ctx_factory):
  ctx = ctx_factory()
  manager_sender = TransactionSender(ctx.manager, ctx.signers['manager'])
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])

  # mint packs
  await owner_sender.send_transaction([
    (
      ctx.rules_tokens.contract_address,
      'mintPack',
      [*uint(1), ctx.rando1.contract_address, 1, ctx.packs_opener.contract_address],
    ),
  ])

  # should revert without packs
  await assert_revert(
    owner_sender.send_transaction([
      (ctx.packs_opener.contract_address, 'takePackFrom', [ctx.rando2.contract_address, *uint(1)]),
    ]),
    'ERC1155: either is not approved or the caller is the zero address',
  )

  # should revert with wrong caller
  await assert_revert(
    rando1_sender.send_transaction([
      (ctx.packs_opener.contract_address, 'takePackFrom', [ctx.rando1.contract_address, *uint(1)]),
    ]),
    'AccessControl: only managers are authorized to perform this action',
  )

  # should revert with wrong pack_id
  await assert_revert(
    owner_sender.send_transaction([
      (ctx.packs_opener.contract_address, 'takePackFrom', [ctx.rando1.contract_address, *uint(1, 1)]),
    ]),
    'PacksOpener: Pack does not exist',
  )


@pytest.mark.asyncio
async def test_on_receive_packs(ctx_factory):
  ctx = ctx_factory()
  manager_sender = TransactionSender(ctx.manager, ctx.signers['manager'])
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])
  rando1_sender = TransactionSender(ctx.rando1, ctx.signers['rando1'])

  # mint packs
  await owner_sender.send_transaction([
    (
      ctx.rules_tokens.contract_address,
      'mintPack',
      [*uint(1), ctx.rando1.contract_address, 2, ctx.packs_opener.contract_address],
    ),
  ])

  # should revert on receive
  await assert_revert(
    rando1_sender.send_transaction([
      (
        ctx.rules_tokens.contract_address,
        'safeTransferFrom',
        [ctx.rando1.contract_address, ctx.packs_opener.contract_address, *uint(1), *uint(1), 1, 0],
      ),
    ]),
  )

  # should work with another recipient
  await rando1_sender.send_transaction([
    (
      ctx.rules_tokens.contract_address,
      'safeTransferFrom',
      [ctx.rando1.contract_address, ctx.rando2.contract_address, *uint(1), *uint(1), 1, 0],
    ),
  ]),
