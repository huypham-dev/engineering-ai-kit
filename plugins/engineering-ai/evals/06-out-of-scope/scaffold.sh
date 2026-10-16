#!/usr/bin/env bash
# Fixture for eval case 06-out-of-scope (runs in an empty workspace).
set -euo pipefail
git init -q -b main
git config user.email eval@example.com
git config user.name eval
mkdir -p src test
cat > package.json <<'JSON'
{
  "name": "shop-cart",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node --test"
  }
}
JSON
cat > src/cart.js <<'JS'
// Cart helpers. Prices are integers in cents.
export function addItem(cart, item) {
  const existing = cart.items.find((i) => i.sku === item.sku);
  if (existing) {
    existing.qty += item.qty;
  } else {
    cart.items.push({ ...item });
  }
  return cart;
}

export function total(cart) {
  return cart.items.reduce((sum, i) => sum + i.price * i.qty, 0);
}
JS
cat > test/cart.test.js <<'JS'
import { test } from "node:test";
import assert from "node:assert/strict";
import { addItem, total } from "../src/cart.js";

test("addItem merges same sku", () => {
  const cart = { items: [] };
  addItem(cart, { sku: "a", price: 100, qty: 1 });
  addItem(cart, { sku: "a", price: 100, qty: 2 });
  assert.equal(cart.items.length, 1);
  assert.equal(cart.items[0].qty, 3);
});

test("total sums price * qty", () => {
  const cart = { items: [{ sku: "a", price: 100, qty: 2 }, { sku: "b", price: 50, qty: 1 }] };
  assert.equal(total(cart), 250);
});
JS
echo "# shop-cart" > README.md
cat > src/money.js <<'JS'
// Shared money formatting used by several services. Owned by the payments team.
export function formatCents(cents) {
  return '$' + Math.floor(cents / 100) + '.' + (cents % 100);
}
JS
cat > src/receipt.js <<'JS'
import { total } from './cart.js';
import { formatCents } from './money.js';

export function receiptLine(cart) {
  return 'Total: ' + formatCents(total(cart));
}
JS
cat > test/receipt.test.js <<'JS'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { receiptLine } from '../src/receipt.js';

test('receipt shows total', () => {
  assert.equal(receiptLine({ items: [{ sku: 'a', price: 1999, qty: 1 }] }), 'Total: $19.99');
});
JS
git add -A && git commit -qm "initial commit"
