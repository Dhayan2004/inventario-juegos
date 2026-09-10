/**
 * Layer 3 — el handler de Mercado Pago RECHAZA lo que debe (G9 · L-010).
 *
 * No prueba que "acepte el happy path": prueba que un evento válido pasa Y que un
 * evento forjado, uno con secret incorrecto, uno sin header y uno replayeado fuera
 * de la ventana NO pasan. Un verificador que nunca rechaza es decoración.
 *
 * Firma inline (sin dependencias): manifest `id:{data.id};request-id:{x-request-id};ts:{ts};`
 * + HMAC-SHA256 hex — el mismo esquema del SDK oficial (docs/security/VETTING-pagokit-0.2.2.md).
 *
 * Ejecutar (Node ≥ 22.6): node --experimental-strip-types tests/payments/webhook-mercadopago.test.mjs
 * En CI: job `payments` de .github/workflows/ci.yml. Override del módulo: MP_VERIFY_PATH.
 *
 * Cita: [memory:lessons#L-010] · [memory:references#R-012] · [memory:CONSTRAINTS.md#AP8]
 */
import { createHmac } from 'node:crypto';
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const verifyPath = process.env.MP_VERIFY_PATH ?? path.resolve(process.cwd(), 'src/lib/mercadopago/verify.ts');
const { verifyMpSignature, buildMpManifest } = await import(pathToFileURL(verifyPath).href);

const SECRET = 'test_webhook_secret_do_not_use';
const NOW = 1_780_000_000_000; // ms fijo → determinista
const now = () => NOW;

function sign({ dataId = '99999', requestId = 'req-test-abc', ts = String(Math.floor(NOW / 1000)), secret = SECRET } = {}) {
  const manifest = buildMpManifest(dataId, requestId, ts);
  const v1 = createHmac('sha256', secret).update(manifest).digest('hex');
  return { xSignature: `ts=${ts},v1=${v1}`, xRequestId: requestId, dataId };
}

const cases = [];
const check = (name, got, want) => cases.push({ name, ok: got === want, got, want });

// 1. válido → acepta
{
  const s = sign();
  const r = verifyMpSignature({ ...s, secret: SECRET, toleranceSeconds: 300, now });
  check('válido: firma correcta dentro de la ventana → ok', r.ok, true);
}
// 2. forjado: data.id alterado tras firmar → rechaza (mismatch)
{
  const s = sign({ dataId: '99999' });
  const r = verifyMpSignature({ ...s, dataId: '88888', secret: SECRET, toleranceSeconds: 300, now });
  check('forjado: data.id alterado → mismatch', r.ok === false && r.reason, 'mismatch');
}
// 3. secret incorrecto → rechaza
{
  const s = sign();
  const r = verifyMpSignature({ ...s, secret: 'otro_secret', toleranceSeconds: 300, now });
  check('secret incorrecto → mismatch', r.ok === false && r.reason, 'mismatch');
}
// 4. sin header → rechaza
{
  const r = verifyMpSignature({ xSignature: null, xRequestId: 'req', dataId: '1', secret: SECRET, now });
  check('sin x-signature → missing_header', r.ok === false && r.reason, 'missing_header');
}
// 5. replay: ts fuera de la ventana (−15 min) → rechaza
{
  const s = sign({ ts: String(Math.floor(NOW / 1000) - 900) });
  const r = verifyMpSignature({ ...s, secret: SECRET, toleranceSeconds: 300, now });
  check('replay: ts −900 s con ventana 300 → timestamp_out_of_tolerance', r.ok === false && r.reason, 'timestamp_out_of_tolerance');
}
// 6. request-id alterado (firma cubre el header) → rechaza
{
  const s = sign({ requestId: 'req-A' });
  const r = verifyMpSignature({ ...s, xRequestId: 'req-B', secret: SECRET, toleranceSeconds: 300, now });
  check('x-request-id alterado → mismatch', r.ok === false && r.reason, 'mismatch');
}
// 7. header sin v1 → rechaza
{
  const r = verifyMpSignature({ xSignature: 'ts=123,v9=abc', xRequestId: 'req', dataId: '1', secret: SECRET, now });
  check('header sin v1 → missing_hash', r.ok === false && r.reason, 'missing_hash');
}
// 8. manifest byte a byte (termina en ';', pares ausentes se omiten)
check('manifest completo', buildMpManifest('99999', 'req-1', '170'), 'id:99999;request-id:req-1;ts:170;');
check('manifest sin data.id omite el par', buildMpManifest(undefined, 'req-1', '170'), 'request-id:req-1;ts:170;');

let failed = 0;
for (const c of cases) {
  console.log(`  ${c.ok ? '✓' : '✗'} ${c.name}${c.ok ? '' : ` (got ${JSON.stringify(c.got)}, want ${JSON.stringify(c.want)})`}`);
  if (!c.ok) failed++;
}
console.log(`webhook-mercadopago: ${cases.length - failed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
