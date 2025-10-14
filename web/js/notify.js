// MoodSync Notifications & Daily Reminders
// ----------------------------------------

// Ask once for browser notification permission (only first visit)
async function requestNotifPermissionOnce() {
  const KEY = 'ms_notif_permission_asked';
  if (localStorage.getItem(KEY)) return; // already asked
  localStorage.setItem(KEY, '1');
  if ('Notification' in window && Notification.permission === 'default') {
    try {
      await Notification.requestPermission();
    } catch (err) {
      console.warn('Notification permission request failed:', err);
    }
  }
}

// Show a browser notification OR a soft banner fallback
function notifyOrBanner(message) {
  // Browser notification (if allowed)
  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification('MoodSync', { body: message, icon: '/images/icon.png' });
    return;
  }

  // Fallback: small floating banner at bottom
  let bar = document.getElementById('ms-banner');
  if (!bar) {
    bar = document.createElement('div');
    bar.id = 'ms-banner';
    bar.style.cssText = `
      position:fixed;
      bottom:16px;
      left:50%;
      transform:translateX(-50%);
      background:#111827;
      color:#fff;
      font-family:sans-serif;
      padding:10px 16px;
      border-radius:10px;
      box-shadow:0 4px 12px rgba(0,0,0,.2);
      z-index:9999;
      transition:opacity .5s ease;
    `;
    document.body.appendChild(bar);
  }
  bar.textContent = message;
  bar.style.opacity = '1';
  setTimeout(() => {
    if (bar) bar.style.opacity = '0';
  }, 4000);
}

// Send one reminder per day (local)
function remindTodayOnce() {
  const KEY = 'ms_last_reminder_date';
  const today = new Date().toISOString().slice(0, 10);
  const last = localStorage.getItem(KEY);
  if (last === today) return; // already reminded today
  localStorage.setItem(KEY, today);
  notifyOrBanner("How's your day going? Log your mood 😊");
}

// Schedule an evening check-in (8 PM local time)
function scheduleEveningReminder() {
  const now = new Date();
  const target = new Date();
  target.setHours(20, 0, 0, 0); // 8:00 PM
  if (target <= now) target.setDate(target.getDate() + 1);
  const msUntil = target - now;
  setTimeout(() => notifyOrBanner('Evening check-in time ✨'), msUntil);
}

// Initialize notifications on load
document.addEventListener('DOMContentLoaded', () => {
  requestNotifPermissionOnce();
  remindTodayOnce();
  scheduleEveningReminder();
});
