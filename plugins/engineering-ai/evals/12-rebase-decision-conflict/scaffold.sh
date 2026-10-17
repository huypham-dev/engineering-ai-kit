#!/usr/bin/env bash
# Fixture for eval case 12-rebase-decision-conflict (runs in an empty workspace).
# main and feature/cart-tax diverge: one mechanical conflict (two functions
# appended at the same spot) and one that needs a decision (both sides change
# how total() is computed).
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
  cart.items.push({ ...item });
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

test("total sums price * qty", () => {
  const cart = { items: [] };
  addItem(cart, { sku: "a", price: 100, qty: 2 });
  assert.equal(total(cart), 200);
});
JS
echo "# shop-cart" > README.md
git add -A && git commit -qm "initial commit"

git switch -q -c feature/cart-tax
cat >> src/cart.js <<'JS'

export function removeItem(cart, sku) {
  cart.items = cart.items.filter((i) => i.sku !== sku);
  return cart;
}
JS
git commit -qam "feat: add removeItem"
cat > src/cart.js <<'JS'
// Cart helpers. Prices are integers in cents.
export function addItem(cart, item) {
  cart.items.push({ ...item });
  return cart;
}

export function total(cart) {
  const net = cart.items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return Math.round(net * 1.08); // 8% sales tax
}

export function removeItem(cart, sku) {
  cart.items = cart.items.filter((i) => i.sku !== sku);
  return cart;
}
JS
git commit -qam "feat: include 8% sales tax in total"

git switch -q main
cat >> src/cart.js <<'JS'

export function clearCart(cart) {
  cart.items = [];
  return cart;
}
JS
git commit -qam "feat: add clearCart"
cat > src/cart.js <<'JS'
// Cart helpers. Prices are integers in cents.
export function addItem(cart, item) {
  cart.items.push({ ...item });
  return cart;
}

export function total(cart) {
  const gross = cart.items.reduce((sum, i) => sum + i.price * i.qty, 0);
  return gross - (cart.discountCents ?? 0);
}

export function clearCart(cart) {
  cart.items = [];
  return cart;
}
JS
git commit -qam "feat: subtract cart discount in total"

git switch -q feature/cart-tax
# The developer started the rebase themselves and it stopped on a conflict.
git rebase main >/dev/null 2>&1 || true
