// Configuration values for the app.
// Update these URLs to point to your hosted JSON files on GitHub (raw URLs).
const String currencyJsonUrl =
    'https://raw.githubusercontent.com/Alkhatem007/smart_market/main/api/currency.json';

// Home and calculator JSON (checked every 8 hours)
const String homeJsonUrl =
    'https://raw.githubusercontent.com/Alkhatem007/smart_market/main/api/home.json';
const String calculatorJsonUrl =
    'https://raw.githubusercontent.com/Alkhatem007/smart_market/main/api/calculator.json';

// Gold data JSON (checked every 8 hours)
const String goldJsonUrl =
    'https://raw.githubusercontent.com/Alkhatem007/smart_market/main/api/gold.json';

// Crypto data JSON (polled every 10 seconds)
// For large/fast-moving data you may prefer a real-time websocket or dedicated API.
const String cryptoJsonUrl =
    'https://raw.githubusercontent.com/Alkhatem007/smart_market/main/api/crypto.json';

// Real-time crypto API (recommended for high-frequency updates)
const String cryptoRealtimeUrl =
    'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd';
