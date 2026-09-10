/**
 * Voice Section — surfaces voice.json hooks + cta_examples + safe_words
 * + avoid_words. el-evaluador validates output copy elsewhere by parsing
 * voice.json directly; this section is the human-readable mirror.
 *
 * Note: hardcoded examples here come from voice.json captured during
 * Discovery — generate-showcase.md fills the templates.
 */

const HOOKS = {{ voice.hooks | as_json_array }}
const CTA_EXAMPLES = {{ voice.cta_examples | as_json_array }}
const SAFE_WORDS = {{ voice.safe_words | as_json_array }}
const AVOID_WORDS_PROJECT = {{ voice.avoid_words_project | as_json_array | default: [] }}

export function VoiceSection() {
  return (
    <section aria-labelledby="voice-title">
      <h2
        id="voice-title"
        className="font-[family-name:var(--font-display)] text-3xl font-bold text-[var(--color-text)]"
      >
        Voice
      </h2>
      <p className="mt-2 text-sm text-[var(--color-text-muted)]">
        Tone axes + hooks + CTA style. Source: <code className="font-mono">brand/voice.json</code>.
      </p>

      <div className="mt-[var(--space-8)] grid gap-[var(--space-6)] md:grid-cols-2">
        {/* Hooks */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            voice.hooks
          </p>
          <ul className="mt-[var(--space-4)] space-y-[var(--space-3)]">
            {HOOKS.map((hook: string, i: number) => (
              <li
                key={i}
                className="font-[family-name:var(--font-display)] text-xl font-semibold leading-tight text-[var(--color-text)]"
              >
                <span className="text-[var(--color-text-subtle)]">"</span>
                {hook}
                <span className="text-[var(--color-text-subtle)]">"</span>
              </li>
            ))}
          </ul>
        </article>

        {/* CTAs */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            voice.cta_examples · style: {{ voice.cta_style }}
          </p>
          <ul className="mt-[var(--space-4)] space-y-[var(--space-2)]">
            {CTA_EXAMPLES.map((cta: string, i: number) => (
              <li key={i} className="text-base text-[var(--color-text)]">
                {cta}
              </li>
            ))}
          </ul>
        </article>

        {/* Safe words */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            safe_words · marca-específico
          </p>
          <div className="mt-[var(--space-4)] flex flex-wrap gap-[var(--gap-xs)]">
            {SAFE_WORDS.map((word: string, i: number) => (
              <span
                key={i}
                className="rounded-[var(--radius-sm)] border border-[var(--color-border)] bg-[var(--color-surface)] px-[var(--space-2)] py-[var(--space-1)] font-mono text-xs text-[var(--color-text)]"
              >
                {word}
              </span>
            ))}
          </div>
        </article>

        {/* Avoid words */}
        <article className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-elevated)] p-[var(--space-6)]">
          <p className="font-mono text-xs uppercase tracking-widest text-[var(--color-text-subtle)]">
            avoid_words · adicionales del proyecto
          </p>
          {AVOID_WORDS_PROJECT.length === 0 ? (
            <p className="mt-[var(--space-4)] text-sm text-[var(--color-text-subtle)]">
              Solo el baseline Forja (23 palabras prohibidas por defecto). Sin
              adiciones project-specific.
            </p>
          ) : (
            <div className="mt-[var(--space-4)] flex flex-wrap gap-[var(--gap-xs)]">
              {AVOID_WORDS_PROJECT.map((word: string, i: number) => (
                <span
                  key={i}
                  className="rounded-[var(--radius-sm)] bg-[var(--color-danger)] px-[var(--space-2)] py-[var(--space-1)] font-mono text-xs text-white opacity-70 line-through"
                >
                  {word}
                </span>
              ))}
            </div>
          )}
        </article>
      </div>
    </section>
  )
}
