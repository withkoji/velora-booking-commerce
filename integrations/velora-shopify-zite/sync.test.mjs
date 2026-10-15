import test from 'node:test';
import assert from 'node:assert/strict';
import { planSync, run } from './sync.mjs';

const shop = 'example.myshopify.com';
const product = { title: 'Test Service', description: 'Description', productType: 'Spa', status: 'ACTIVE', variants: { pageInfo: { hasNextPage: false }, nodes: [{ id: 'gid://shopify/ProductVariant/1', title: 'Default Title', price: '95.00' }] } };
const existing = () => ({ id: 'record-1', fields: { ...planSync([product], [], shop)[0].values, Active: true, Duration: 60, 'Deposit Percent': 0.5, Provider: ['provider-1'] } });

test('new service imports inactive without inventing booking rules', () => {
  const plan = planSync([product], [], shop);
  assert.equal(plan[0].values.Active, false);
  assert.equal(plan[0].values.Price, 95);
  assert.equal(plan[0].values.Duration, undefined);
  assert.equal(plan[0].values['Deposit Percent'], undefined);
});
test('rerun is idempotent and retains booking settings', () => {
  assert.equal(planSync([product], [existing()], shop)[0].action, 'unchanged');
});
test('price changes update only the price', () => {
  const changed = { ...product, variants: { ...product.variants, nodes: [{ ...product.variants.nodes[0], price: '105.00' }] } };
  assert.deepEqual(planSync([changed], [existing()], shop)[0].values, { Price: 105 });
});
test('archived products deactivate but are never deleted', () => {
  assert.deepEqual(planSync([{ ...product, status: 'ARCHIVED' }], [existing()], shop)[0].values, { Active: false });
});
test('legacy title collision blocks the entire plan', () => {
  assert.throws(() => planSync([product], [{ id: 'old', fields: { 'Service ID': 'legacy', 'Service Name': 'Test Service' } }], shop), /Map its Service ID/);
});
test('duplicate stable identities fail closed', () => {
  assert.throws(() => planSync([product], [existing(), existing()], shop), /Duplicate/);
});
test('variant truncation and invalid prices are rejected', () => {
  assert.throws(() => planSync([{ ...product, variants: { ...product.variants, pageInfo: { hasNextPage: true } } }], [], shop), /100 variants/);
  assert.throws(() => planSync([{ ...product, variants: { ...product.variants, nodes: [{ ...product.variants.nodes[0], price: 'bad' }] } }], [], shop), /Invalid Shopify price/);
});
test('dry run performs reads only and apply uses documented record body', async () => {
  const savedFetch = globalThis.fetch;
  const calls = [];
  const env = { SHOPIFY_SHOP_DOMAIN: shop, SHOPIFY_ADMIN_ACCESS_TOKEN: 'test-only', SHOPIFY_SERVICE_QUERY: 'tag:velora-service', ZITE_API_KEY: 'test-only' };
  globalThis.fetch = async (url, options) => {
    calls.push({ url, ...options, body: JSON.parse(options.body) });
    const payload = url.includes('graphql') ? { data: { shop: { myshopifyDomain: shop, currencyCode: 'USD' }, products: { nodes: [product], pageInfo: { hasNextPage: false } } } } : url.endsWith('/list') ? { records: [], hasMore: false } : { id: 'created' };
    return new Response(JSON.stringify(payload), { status: 200 });
  };
  try {
    await run(env);
    assert.equal(calls.length, 2);
    await run({ ...env, DRY_RUN: 'false' });
    assert.equal(calls.at(-1).method, 'POST');
    assert.equal(calls.at(-1).body.record.Active, false);
    assert.equal(calls.at(-1).body.record.Price, 95);
  } finally { globalThis.fetch = savedFetch; }
});
