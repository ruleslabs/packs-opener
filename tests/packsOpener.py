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


@pytest.mark.asyncio
async def test_open_pack(ctx_factory):
  ctx = ctx_factory()
  manager_sender = TransactionSender(ctx.manager, ctx.signers['manager'])
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])

  card1_1_id = (await ctx.rules_cards.getCardId((cardModel1, 1)).call()).result.card_id
  card1_2_id = (await ctx.rules_cards.getCardId((cardModel1, 2)).call()).result.card_id
  card1_3_id = (await ctx.rules_cards.getCardId((cardModel1, 3)).call()).result.card_id
  card2_1_id = (await ctx.rules_cards.getCardId((cardModel2, 1)).call()).result.card_id
  card2_2_id = (await ctx.rules_cards.getCardId((cardModel2, 2)).call()).result.card_id
  card3_1_id = (await ctx.rules_cards.getCardId((cardModel3, 1)).call()).result.card_id

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

  await manager_sender.send_transaction([
    (
      ctx.packs_opener.contract_address,
      'openPackTo',
      [
        ctx.rando1.contract_address,
        *uint(1),
        3,
        *to_starknet_args(cardModel1),
        1,
        *to_starknet_args(cardModel1),
        2,
        *to_starknet_args(cardModel3),
        1,
        3,
        *metadata,
        *metadata,
        *metadata,
      ],
    ),
    (
      ctx.packs_opener.contract_address,
      'openPackTo',
      [
        ctx.rando1.contract_address,
        *uint(1),
        3,
        *to_starknet_args(cardModel2),
        1,
        *to_starknet_args(cardModel1),
        3,
        *to_starknet_args(cardModel2),
        2,
        3,
        *metadata,
        *metadata,
        *metadata,
      ],
    ),
  ]),

  assert (await ctx.packs_opener.balanceOf(ctx.rando1.contract_address, uint(1)).call()).result.balance == uint(0)

  assert (await ctx.rules_tokens.balanceOf(ctx.rando1.contract_address, card1_1_id).call()).result.balance == uint(1)
  assert (await ctx.rules_tokens.balanceOf(ctx.rando1.contract_address, card1_2_id).call()).result.balance == uint(1)
  assert (await ctx.rules_tokens.balanceOf(ctx.rando1.contract_address, card1_3_id).call()).result.balance == uint(1)
  assert (await ctx.rules_tokens.balanceOf(ctx.rando1.contract_address, card2_1_id).call()).result.balance == uint(1)
  assert (await ctx.rules_tokens.balanceOf(ctx.rando1.contract_address, card2_2_id).call()).result.balance == uint(1)
  assert (await ctx.rules_tokens.balanceOf(ctx.rando1.contract_address, card3_1_id).call()).result.balance == uint(1)


@pytest.mark.asyncio
async def test_invalid_open_pack(ctx_factory):
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

  # should revert without packs sent

  await assert_revert(
    manager_sender.send_transaction([
      (
        ctx.packs_opener.contract_address,
        'openPackTo',
        [
          ctx.rando2.contract_address,
          *uint(1),
          3,
          *to_starknet_args(cardModel1),
          1,
          *to_starknet_args(cardModel1),
          2,
          *to_starknet_args(cardModel3),
          1,
          3,
          *metadata,
          *metadata,
          *metadata,
        ],
      ),
    ]),
    'PacksOpener: null balance for this pack',
  )


@pytest.mark.asyncio
async def test_upgrade(ctx_factory):
  ctx = ctx_factory()
  owner_sender = TransactionSender(ctx.owner, ctx.signers['owner'])
  manager_sender = TransactionSender(ctx.manager, ctx.signers['manager'])

  upgrade_impl = await declare(ctx.starknet, 'src/test/upgrade.cairo')

  # should revert with non owner upgrade
  await assert_revert(
    manager_sender.send_transaction([(ctx.packs_opener.contract_address, 'upgrade', [upgrade_impl.class_hash])]),
  )

  # should revert with null upgrade
  await assert_revert(
    owner_sender.send_transaction([(ctx.packs_opener.contract_address, 'upgrade', [0])]),
    'PacksOpener: new implementation cannot be null'
  )

  # should revert with double initialization
  await assert_revert(
    owner_sender.send_transaction([(ctx.packs_opener.contract_address, 'initialize', [1, 1])]),
    'PacksOpener: contract already initialized'
  )

  await owner_sender.send_transaction([(ctx.packs_opener.contract_address, 'upgrade', [upgrade_impl.class_hash])])

  # should still revert with double initialization after upgrade
  await assert_revert(
    owner_sender.send_transaction([(ctx.packs_opener.contract_address, 'initialize', [])]),
    'Mock: contract already initialized'
  )

  await owner_sender.send_transaction([(ctx.packs_opener.contract_address, 'reset', [])])
  await owner_sender.send_transaction([(ctx.packs_opener.contract_address, 'initialize', [])])

  # should revert with double initialization
  await assert_revert(
    owner_sender.send_transaction([(ctx.packs_opener.contract_address, 'initialize', [])]),
    'Mock: contract already initialized'
  )
