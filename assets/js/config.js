/* ==========================================================================
   Durham Wiffle Ball - runtime config

   The Supabase ANON key is meant to be public. It is safe here ONLY because
   every table has Row Level Security on with no policies, so all access runs
   through the SECURITY DEFINER functions in supabase/schema.sql.
   NEVER put the service_role key in this file.

   Leave values blank and the site still works: registration, waiver, and
   attendance show a "not connected yet" state instead of breaking.
   ========================================================================== */
window.DS_CONFIG = {
  // Supabase > Project Settings > Data API
  SUPABASE_URL: 'https://grlcweyhzvzceftdkxop.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdybGN3ZXloenZ6Y2VmdGRreG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYyODU5MjgsImV4cCI6MjEwMTg2MTkyOH0.fh7Q3xZZtixmmONcMFkdsYlTPb7LadOgLiFy19Q8J7k',

  // Hosted checkout. Stripe Payment Link, or a PayPal hosted button URL.
  // These are public URLs, nothing secret.
  REGISTRATION_FEE_URL: 'https://paypal.me/plaync',
  REGISTRATION_FEE_LABEL: 'Wiffle ball registration',
  DONATE_URL: 'https://paypal.me/plaync',

  CURRENT_SEASON: '2026-wiffle',
  WAIVER_VERSION: 'wiffle-2026-v1'
};
