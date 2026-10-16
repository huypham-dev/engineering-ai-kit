#!/usr/bin/env bash
# Fixture for eval case 02-ambiguous-ticket (runs in an empty workspace).
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
git add -A && git commit -qm "initial commit"
