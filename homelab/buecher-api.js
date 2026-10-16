// HomeLabBooks: Zugriff auf die Schnittstelle /buecher/… des Musikwunsch-Dienstes (Port 30370 auf demselben
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
