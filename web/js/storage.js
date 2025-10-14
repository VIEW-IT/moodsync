// Simple localStorage-backed store scoped by username
const MS = (() => {
  const USER_KEY = 'ms_user';

  function getUser() {
    const raw = localStorage.getItem(USER_KEY);
    return raw ? JSON.parse(raw) : null;
  }
  function saveUser(user) {
    localStorage.setItem(USER_KEY, JSON.stringify(user));
  }
  function usernameOrDefault() {
    const u = getUser();
    return u?.username || 'guest';
  }
  function entriesKey(username) {
    return `ms_entries_${username}`;
  }
  function listEntries(username = usernameOrDefault()) {
    const raw = localStorage.getItem(entriesKey(username));
    return raw ? JSON.parse(raw) : [];
  }
  function saveEntries(entries, username = usernameOrDefault()) {
    localStorage.setItem(entriesKey(username), JSON.stringify(entries));
  }
  function addEntry(entry, username = usernameOrDefault()) {
    const list = listEntries(username);
    list.unshift(entry);
    saveEntries(list, username);
  }
  function getEntryById(id, username = usernameOrDefault()){
    return listEntries(username).find(e => e.id === id) || null;
  }
  function updateEntry(updated, username = usernameOrDefault()){
    const list = listEntries(username);
    const i = list.findIndex(e => e.id === updated.id);
    if (i !== -1) { list[i] = updated; saveEntries(list, username); return true; }
    return false;
  }
  function deleteEntry(id, username = usernameOrDefault()){
    const list = listEntries(username).filter(e => e.id !== id);
    saveEntries(list, username);
  }

  function uid() {
    return Math.random().toString(36).slice(2, 10) + Date.now().toString(36).slice(-6);
  }
  function todayISO() {
    return new Date().toISOString().slice(0, 10);
  }

  return {
    getUser, saveUser, listEntries, addEntry,
    getEntryById, updateEntry, deleteEntry,
    uid, todayISO, usernameOrDefault
  };
})();
