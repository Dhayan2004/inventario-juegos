/**
 * Capacitor config — Mode B
 *
 * Wraps web Next.js codebase (Mode A PWA must run first).
 * Cita: [docs:capacitor]
 */
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: '{{ APP_ID }}', // com.yourcompany.appname (reverse-DNS)
  appName: '{{ APP_NAME }}',
  webDir: 'out', // Next.js output: 'export' target
  server: {
    androidScheme: 'https',
  },
  plugins: {
    PushNotifications: {
      presentationOptions: ['badge', 'sound', 'alert'],
    },
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '{{ TOKEN_BACKGROUND_COLOR }}',
      androidSplashResourceName: 'splash',
      androidScaleType: 'CENTER_CROP',
      showSpinner: false,
    },
    StatusBar: {
      style: 'DARK',
      backgroundColor: '{{ TOKEN_PRIMARY_COLOR }}',
    },
  },
  ios: {
    contentInset: 'always',
  },
  android: {
    allowMixedContent: false,
  },
};

export default config;
