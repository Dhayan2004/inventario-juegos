/**
 * Mercado Pago — verificación de firma de webhook (módulo PURO, sin imports de app).
 *
 * Esquema (re-verificado contra el SDK oficial mercadopago/sdk-nodejs
 * src/utils/webhook/index.ts — docs/security/VETTING-pagokit-0.2.2.md §4):
 *   header  x-signature:  ts=<unix_seconds>,v1=<hex_hmac>
 *   header  x-request-id: <uuid>
 *   query   data.id:      id del recurso
 *   manifest = `id:${data.id};request-id:${x-request-id};ts:${ts};`   ← termina en ';'
 *   hmac    = HMAC-SHA256(secret, manifest) en hex, comparado en tiempo constante
 *
 * MP NO firma el body (familia hmac_field_concat): todo lo demás del payload es
 * attacker-controlled aunque la firma pase → re-fetch obligatorio (route.ts).
 * Las notificaciones de QR no van firmadas — no pasan por aquí.
 *
 * Sin dependencias fuera de node:crypto para que la Layer 3 (tests/payments/
 * webhook.test.mjs) lo ejecute tal cual con `node --experimental-strip-types`.
 *
 * Cita: [memory:lessons#L-002] · [memory:references#R-012] · [docs:mercadopago@v2]
 */
import { createHmac, timingSafeEqual } from 'node:crypto';

export interface MpSignatureInput {
  xSignature: string | null | undefined;
  xRequestId: string | null | undefined;
  dataId: string | null | undefined;
  secret: string;
  /** Ventana anti-replay en segundos (recomendado 300). `undefined` = sin chequeo de tiempo. */
  toleranceSeconds?: number;
  /** Reloj inyectable (tests). Default Date.now. */
  now?: () => number;
}

export type MpSignatureResult =
  | { ok: true; ts: string }
  | { ok: false; reason: 'missing_header' | 'malformed_header' | 'missing_ts' | 'missing_hash' | 'mismatch' | 'timestamp_out_of_tolerance' };

const VERSION_KEY = /^v\d+$/;

export function buildMpManifest(dataId: string | null | undefined, requestId: string | null | undefined, ts: string): string {
  const parts: string[] = [];
  if (dataId) parts.push(`id:${dataId}`);
  if (requestId) parts.push(`request-id:${requestId}`);
  parts.push(`ts:${ts}`);
  return parts.join(';') + ';';
}

function constantTimeEquals(a: string, b: string): boolean {
  const ba = Buffer.from(a);
  const bb = Buffer.from(b);
  if (ba.byteLength !== bb.byteLength) return false;
  return timingSafeEqual(ba, bb);
}

export function verifyMpSignature(input: MpSignatureInput): MpSignatureResult {
  const header = Array.isArray(input.xSignature) ? input.xSignature[0] : input.xSignature;
  if (!header || !header.trim()) return { ok: false, reason: 'missing_header' };

  let ts: string | undefined;
  const hashes: Record<string, string> = {};
  for (const part of header.split(',')) {
    const eq = part.indexOf('=');
    if (eq === -1) continue;
    const key = part.slice(0, eq).trim().toLowerCase();
    const value = part.slice(eq + 1).trim();
    if (!key || !value) continue;
    if (key === 'ts') ts = value;
    else if (VERSION_KEY.test(key)) hashes[key] = value;
  }
  if (!ts && Object.keys(hashes).length === 0) return { ok: false, reason: 'malformed_header' };
  if (!ts) return { ok: false, reason: 'missing_ts' };
  const received = hashes['v1'];
  if (!received) return { ok: false, reason: 'missing_hash' };

  const manifest = buildMpManifest(input.dataId ?? undefined, input.xRequestId ?? undefined, ts);
  const computed = createHmac('sha256', input.secret).update(manifest).digest('hex');
  if (!constantTimeEquals(computed, received)) return { ok: false, reason: 'mismatch' };

  if (input.toleranceSeconds !== undefined) {
    const nowSec = Math.floor((input.now ?? Date.now)() / 1000);
    const tsNum = Number(ts);
    if (!Number.isFinite(tsNum) || Math.abs(nowSec - tsNum) > input.toleranceSeconds) {
      return { ok: false, reason: 'timestamp_out_of_tolerance' };
    }
  }
  return { ok: true, ts };
}
