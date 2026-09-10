/**
 * SendGrid dynamic-template metadata — barrel export.
 *
 * Cada export es un descriptor (`.id`, `.templateId()`, `.subject(data)`).
 * El HTML real vive en el SendGrid dashboard (uploaded externamente).
 *
 * @see ./Welcome · ./MagicLink · ./PasswordReset · ./InvoiceReceipt
 *      · ./PaymentFailed · ./SubscriptionCanceled · ./EmailChangedConfirmation
 */
export { WelcomeTemplate } from './Welcome';
export type { WelcomeData } from './Welcome';
export { MagicLinkTemplate } from './MagicLink';
export type { MagicLinkData } from './MagicLink';
export { PasswordResetTemplate } from './PasswordReset';
export type { PasswordResetData } from './PasswordReset';
export { InvoiceReceiptTemplate } from './InvoiceReceipt';
export type { InvoiceReceiptData } from './InvoiceReceipt';
export { PaymentFailedTemplate } from './PaymentFailed';
export type { PaymentFailedData } from './PaymentFailed';
export { SubscriptionCanceledTemplate } from './SubscriptionCanceled';
export type { SubscriptionCanceledData } from './SubscriptionCanceled';
export { EmailChangedConfirmationTemplate } from './EmailChangedConfirmation';
export type { EmailChangedConfirmationData } from './EmailChangedConfirmation';
