// --- Helpers ---
function getUsername() {
  try {
    const raw = localStorage.getItem('ms_user');
    if (!raw) return null;
    const u = JSON.parse(raw);
    return u?.username || null;
  } catch {
    return null;
  }
}

// Website → App deep link (Universal Link first, scheme fallback)
function openInApp() {
  const username = getUsername() || 'guest';

  // TODO: change this to your real domain when you have it
  const universal = `https://moodsync.example/ul/app?u=${encodeURIComponent(username)}`;

  // Works immediately once your iOS app registers the scheme in Xcode
  const scheme = `moodsync://dashboard?u=${encodeURIComponent(username)}`;

  // Try Universal Link first (iOS will open app if installed, else stay on web)
  window.location.href = universal;

  // Fallback to custom scheme after a short delay (helps on Android/others)
  setTimeout(() => {
    window.location.href = scheme;
  }, 700);
}

// App → Website helper (used by “View My Journal Online” in the app)
function userPublicUrl(username) {
  return location.origin + '/u/?u=' + encodeURIComponent(username);
}

// Highlight current nav item
function setActiveNav() {
  const path = location.pathname.replace(/\/index\.html$/, '/') || '/';
  document.querySelectorAll('nav a[data-path]').forEach(a => {
    if (a.dataset.path === path) a.classList.add('active');
  });
}
document.addEventListener('DOMContentLoaded', setActiveNav);
