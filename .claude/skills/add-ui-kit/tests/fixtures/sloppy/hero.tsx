/**
 * FIXTURE NEGATIVO — hero deliberadamente "sloppy" (Anshu / landing-anti-slop.md).
 * Este archivo DEBE fallar los checks 9–12 del Anti-Slop Gate (anti-slop-gate.sh):
 *   9  glow_stack            — blur + gradient + shadow-pink-500/50 apilados en un mismo elemento
 *   10 reduced_motion        — animate-in / transition-transform sin motion-reduce ni prefers-reduced-motion
 *   11 layout_prop_animation — transition-all (anima width/height/padding… = layout shift)
 *   12 hero_default          — grid-cols-2 texto-izq / imagen-der + paleta índigo/púrpura sin autorización
 * NO es un template. No se copia a ningún proyecto. Solo alimenta el test.
 */
export function SloppyHero() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500">
      <div className="absolute -top-24 -left-24 h-96 w-96 rounded-full bg-pink-400 blur-3xl shadow-pink-500/50 bg-gradient-to-r from-pink-400 to-purple-600" />
      <div className="mx-auto grid max-w-6xl grid-cols-1 items-center gap-12 px-6 py-24 lg:grid-cols-2">
        <div className="animate-in fade-in slide-in-from-left-8 duration-700">
          <h1 className="text-5xl font-bold text-white">Empower your business with AI</h1>
          <p className="mt-4 text-lg text-white/80">The all-in-one platform to supercharge your productivity.</p>
          <button className="mt-8 rounded-3xl bg-white px-6 py-3 font-semibold text-purple-600 shadow-2xl transition-all hover:scale-105">
            Get Started
          </button>
        </div>
        <img src="/hero.png" alt="Dashboard" className="w-full rounded-3xl shadow-2xl transition-transform hover:scale-105" />
      </div>
    </section>
  );
}
