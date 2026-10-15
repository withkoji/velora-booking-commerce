import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const query = await readFile(new URL('./products.graphql', import.meta.url), 'utf8');
const fail = message => { throw new Error(message); };
const normalize = value => String(value ?? '').trim().toLowerCase().replace(/\s+/g, ' ');

export function planSync(products, records, shop) {
  const byId = new Map();
  for (const record of records) {
    const id = record.fields['Service ID'];
    if (byId.has(id)) fail('Duplicate Service ID in Zite; resolve before syncing.');
    byId.set(id, record);
  }
  const seen = new Set();
  return products.flatMap(product => {
    if (product.variants.pageInfo.hasNextPage) fail('Product has over 100 variants; narrow the service catalog before syncing.');
    return product.variants.nodes.map(variant => {
      const serviceId = `shopify:${shop}:${variant.id}`;
      if (seen.has(serviceId)) fail('Duplicate source variant.');
      seen.add(serviceId);
      const name = variant.title === 'Default Title' ? product.title : `${product.title} — ${variant.title}`;
      const existing = byId.get(serviceId);
      if (!existing && records.some(r => normalize(r.fields['Service Name']) === normalize(name))) {
        fail('An existing service has the same title without a Shopify identity. Map its Service ID explicitly before syncing.');
      }
      const price = Number(variant.price);
      if (!Number.isFinite(price) || price < 0) fail('Invalid Shopify price.');
      const values = {
        'Service ID': serviceId,
        'Service Name': name,
        'Description': product.description,
        'Category': product.productType,
        'Price': price,
      };
      // Shopify cannot activate a service. Zite operations staff control readiness.
      if (!existing || product.status !== 'ACTIVE') values.Active = false;
      const patch = Object.fromEntries(Object.entries(values).filter(([key, value]) => !existing || existing.fields[key] !== value));
      return { action: existing ? (Object.keys(patch).length ? 'update' : 'unchanged') : 'create', recordId: existing?.id, values: patch };
    });
  });
}

async function request(url, headers, method = 'POST', body) {
  // Never auto-retry writes: a timed-out create may already have succeeded.
  const response = await fetch(url, {
    method, headers: { ...headers, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(30000), redirect: 'error',
  });
  if (!response.ok) fail(`API request failed (${response.status}); inspect configuration and rerun after reconciliation.`);
  const result = await response.json();
  if (result.errors?.length || result.error) fail('API returned an error; no response payload logged.');
  return result;
}

export async function run(env = process.env) {
  for (const name of ['SHOPIFY_SHOP_DOMAIN', 'SHOPIFY_ADMIN_ACCESS_TOKEN', 'SHOPIFY_SERVICE_QUERY', 'ZITE_API_KEY']) {
    if (!env[name]) fail(`Missing ${name}`);
  }
  if (!/^[a-z0-9][a-z0-9-]*\.myshopify\.com$/.test(env.SHOPIFY_SHOP_DOMAIN)) fail('Use the verified canonical myshopify.com domain.');
  if (!['true', 'false', undefined].includes(env.DRY_RUN)) fail('DRY_RUN must be true or false.');
  const dryRun = env.DRY_RUN !== 'false';
  const domain = env.SHOPIFY_SHOP_DOMAIN;
  const shopHeaders = { 'X-Shopify-Access-Token': env.SHOPIFY_ADMIN_ACCESS_TOKEN };
  const products = [];
  let after = null;
  do {
    const result = await request(`https://${domain}/admin/api/2026-07/graphql.json`, shopHeaders, 'POST', {
      query, variables: { query: env.SHOPIFY_SERVICE_QUERY, after },
    });
    if (result.data?.shop?.myshopifyDomain !== domain || result.data.shop.currencyCode !== 'USD') fail('Shop identity or USD currency check failed.');
    const page = result.data.products;
    products.push(...page.nodes);
    if (page.pageInfo.hasNextPage && (!page.pageInfo.endCursor || page.pageInfo.endCursor === after)) fail('Invalid Shopify pagination.');
    after = page.pageInfo.hasNextPage ? page.pageInfo.endCursor : null;
  } while (after);
  if (!products.length) fail('No selected service products found; check SHOPIFY_SERVICE_QUERY.');
  const base = 'https://tables.zite.com/api/v1/bases/14f87f80d78b0a99/tables/teDwGUqase8/records';
  const ziteHeaders = { Authorization: `Bearer ${env.ZITE_API_KEY}` };
  const records = [];
  for (let offset = 0; ; offset += 500) {
    const page = await request(`${base}/list`, ziteHeaders, 'POST', { limit: 500, offset });
    if (!Array.isArray(page.records) || typeof page.hasMore !== 'boolean') fail('Unexpected Zite list response.');
    records.push(...page.records);
    if (!page.hasMore) break;
    if (!page.records.length) fail('Invalid Zite pagination.');
  }
  // Validate the full plan before making the first write.
  const plan = planSync(products, records, domain);
  const counts = { create: 0, update: 0, unchanged: 0 };
  for (const item of plan) {
    counts[item.action]++;
    if (!dryRun && item.action !== 'unchanged') {
      await request(item.action === 'create' ? base : `${base}/${encodeURIComponent(item.recordId)}`, ziteHeaders,
        item.action === 'create' ? 'POST' : 'PATCH', { record: item.values });
    }
  }
  console.log(JSON.stringify({ dryRun, ...counts }));
  return { dryRun, ...counts };
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  run().catch(error => { console.error(error.message); process.exitCode = 1; });
}
