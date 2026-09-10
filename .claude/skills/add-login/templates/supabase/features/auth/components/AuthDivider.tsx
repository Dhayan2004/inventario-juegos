// AuthDivider — visual separator between OAuth and email/password forms.
// R10: usa border + text del brand.css (no hex literals, no Tailwind defaults).
//
// Cita: [memory:CONSTRAINTS.md#R10]
export function AuthDivider() {
  return (
    <div className="relative my-6" role="separator" aria-hidden="true">
      <div className="absolute inset-0 flex items-center">
        <div className="w-full border-t border-border" />
      </div>
      <div className="relative flex justify-center">
        <span className="bg-surface-elevated px-2 text-sm text-text-muted">o</span>
      </div>
    </div>
  );
}
