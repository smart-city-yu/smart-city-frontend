// Cloudflare tunnel — works for both emulator and real device.
// Replace with a new tunnel URL each time you restart cloudflared.
const String kApiHost = 'https://conduct-audit-mines-harris.trycloudflare.com';

// MapTiler API key — get a free key at https://maptiler.com
const String kMapTilerKey = 'T1F9sGhskfSK6lJGRyHK';

const String kMapTilerStyleUrl =
    'https://api.maptiler.com/maps/streets-v2/style.json?key=$kMapTilerKey';
