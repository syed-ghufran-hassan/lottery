import { describe, it, expect, beforeEach } from "vitest";
import { Clarinet, Tx, Chain, Account, types } from "@hirosystems/clarinet-sdk";

describe("Simple Lottery Contract", () => {
  let chain: Chain;
  let accounts: Map<string, Account>;
  let deployer: Account;
  let wallet1: Account;
  let wallet2: Account;

  beforeEach(() => {
    chain = new Chain();
    accounts = chain.accounts;
    deployer = accounts.get("deployer")!;
    wallet1 = accounts.get("wallet_1")!;
    wallet2 = accounts.get("wallet_2")!;
  });

  it("initial total tickets should be zero", () => {
    const block = chain.mineBlock([
      Tx.contractCall(
        "simple-lottery",
        "get-total-tickets",
        [],
        wallet1.address
      ),
    ]);

    block.receipts[0].result.expectUint(0);
  });

  it("allows a user to buy tickets", () => {
    const block = chain.mineBlock([
      Tx.contractCall(
        "simple-lottery",
        "buy-ticket",
        [types.uint(5)],
        wallet1.address
      ),
    ]);

    block.receipts[0].result.expectOk().expectAscii("Ticket purchased");
  });

  it("updates user ticket count correctly", () => {
    chain.mineBlock([
      Tx.contractCall(
        "simple-lottery",
        "buy-ticket",
        [types.uint(3)],
        wallet1.address
      ),
    ]);

    const block = chain.mineBlock([
      Tx.contractCall(
        "simple-lottery",
        "get-tickets",
        [types.principal(wallet1.address)],
        wallet1.address
      ),
    ]);

    block.receipts[0].result.expectUint(3);
  });

  it("accumulates tickets if user buys multiple times", () => {
    chain.mineBlock([
      Tx.contractCall(
        "simple-lottery",
        "buy-ticket",
        [types.uint(2)],
        wallet1.address
      ),
      Tx.contractCall(
        "simple-lottery",
        "buy-ticket",
        [types.uint(4)],
        wallet1.address
      ),
    ]);

    const block = chain.mineBlock([
      Tx.contractCall(
        "simple-lottery",
        "get-tickets",
        [types.principal(wallet1.address)],
        wallet1.address
      ),
    ]);

    block.receipts[0].result.expectUint(6);
  });

  it("updates total tickets across multiple users", () => {
    chain.mineBlock([
      Tx.contractCall(
        "simple-lottery",
        "buy-ticket",
        [types.uint(3)],
        wallet1.address
      ),
      Tx.contractCall(
        "simple-lottery",
        "buy-ticket",
        [types.uint(7)],
        wallet2.address
      ),
    ]);

    const block = chain.mineBlock([
      Tx.contractCall(
        "simple-lottery",
        "get-total-tickets",
        [],
        wallet1.address
      ),
    ]);

    block.receipts[0].result.expectUint(10);
  });

  it("returns zero for users with no tickets", () => {
    const block = chain.mineBlock([
      Tx.contractCall(
        "simple-lottery",
        "get-tickets",
        [types.principal(wallet2.address)],
        wallet2.address
      ),
    ]);

    block.receipts[0].result.expectUint(0);
  });
});
