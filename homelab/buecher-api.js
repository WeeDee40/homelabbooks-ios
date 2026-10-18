// HomeLabBooks: Zugriff auf die Schnittstelle /buecher/… des Medienwunsch-Dienstes (Port 30370 auf demselben
// Rechner wie Audiobookshelf). Läuft über $nativeHttp (CapacitorHttp, also ohne CORS) und weist sich mit dem
// Audiobookshelf-Token der Person aus.
export function buecherBasis(store) {
  const adresse = store.state.user.serverConnectionConfig?.address || ''
  try {
    const u = new URL(adresse)
    return `${u.protocol}//${u.hostname}:30370`
  } catch (e) {
    return ''
  }
}

export function buecherApi(ctx, methode, pfad, daten) {
  return ctx.$nativeHttp.request(methode, buecherBasis(ctx.$store) + pfad, daten, {
    headers: { 'X-ABS-Token': ctx.$store.getters['user/getToken'] || '' }
  })
}

// Sprache der Suche und der Wünsche: 'de' (nur Deutsch, Standard) oder 'alle' (Deutsch + Englisch), pro Gerät gemerkt
export function sprache() {
  try {
    return localStorage.getItem('hlb-sprache') === 'alle' ? 'alle' : 'de'
  } catch (e) {
    return 'de'
  }
}

export function spracheSetzen(wert) {
  try {
    localStorage.setItem('hlb-sprache', wert === 'alle' ? 'alle' : 'de')
  } catch (e) {}
}

// Cover über den Dienst (/buecher/cover/<isbn>) brauchen dessen Adresse; fremde Cover (https://…) bleiben
export function coverUrl(store, url) {
  return url && url.startsWith('/') ? buecherBasis(store) + url : url
}
