<template>
  <div class="w-full h-full overflow-y-auto pb-24">
    <!-- Für dich (persönliche Reihen) oder Stöbern (Kategorien) -->
    <div class="flex mx-4 mt-3 p-0.5 rounded-lg bg-secondary text-sm">
      <button v-for="m in modi" :key="m.wert" type="button" class="flex-1 py-1.5 rounded-md" :class="modus === m.wert ? 'bg-bg text-fg font-semibold shadow' : 'text-fg-muted'" @click="modusAendern(m.wert)">{{ m.text }}</button>
    </div>
    <form class="px-4 pt-3" @submit.prevent="suchen">
      <div class="flex items-center bg-secondary rounded-md px-3">
        <span class="material-symbols text-fg-muted">search</span>
        <input v-model="q" type="search" enterkeyhint="search" class="flex-grow bg-transparent outline-none py-2.5 px-2 text-base" placeholder="Wunsch, z. B. «spannender Krimi für die Ferien»" @search="leer" />
      </div>
      <div class="flex gap-2 mt-2">
        <button v-for="o in sprachen" :key="o.wert" type="button" class="text-xs px-3 py-1 rounded-full border" :class="spracheWahl === o.wert ? 'bg-fg text-bg border-fg' : 'border-border text-fg-muted'" @click="spracheAendern(o.wert)">{{ o.text }}</button>
      </div>
    </form>
    <homelab-buch-stoebern v-if="modus === 'stoebern' && !gesucht" :sprache="spracheWahl" @oeffnen="oeffnen" />
    <div v-else-if="laedt" class="flex flex-col items-center justify-center py-16 text-fg-muted">
      <svg class="animate-spin mb-3" style="width: 28px; height: 28px" viewBox="0 0 24 24"><path fill="currentColor" d="M12,4V2A10,10 0 0,0 2,12H4A8,8 0 0,1 12,4Z" /></svg>
      <p class="text-sm">{{ q ? 'Suche läuft …' : 'Lädt deine Empfehlungen …' }}</p>
    </div>
    <p v-else-if="fehler" class="px-4 py-10 text-center text-sm text-fg-muted">{{ fehler }}</p>
    <template v-else>
      <section v-for="reihe in reihen" :key="reihe.titel" class="mt-5">
        <h2 class="px-4 mb-2 text-base font-semibold">{{ reihe.titel }}</h2>
        <div class="flex gap-3 overflow-x-auto px-4 pb-1 no-scroll">
          <homelab-buch-karte v-for="e in reihe.eintraege" :key="e.provider + e.book_id" :eintrag="e" @oeffnen="oeffnen" @ablehnen="ablehnen" />
        </div>
      </section>
      <p v-if="!reihen.length" class="px-4 py-10 text-center text-sm text-fg-muted">Nichts gefunden.</p>
    </template>
    <homelab-buch-details v-model="zeigeDetails" :eintrag="auswahl" @gewuenscht="markieren" />
  </div>
</template>

<script>
// HomeLabBooks: Tab «Entdecken» (Reihen und Suche aus /buecher/… des Medienwunsch-Dienstes)
import { buecherApi, sprache, spracheSetzen } from '~/homelab/buecher-api'

function gemerkterModus() {
  try {
    return localStorage.getItem('hlb-modus') === 'stoebern' ? 'stoebern' : 'fuerdich'
  } catch (e) {
    return 'fuerdich'
  }
}

export default {
  data() {
    return { q: '', gesucht: false, modus: gemerkterModus(), modi: [{ wert: 'fuerdich', text: 'Für dich' }, { wert: 'stoebern', text: 'Stöbern' }],
      reihen: [], laedt: false, fehler: '', auswahl: null, zeigeDetails: false, spracheWahl: sprache(),
      sprachen: [{ wert: 'de', text: 'Nur Deutsch' }, { wert: 'alle', text: 'Deutsch + Englisch' }] }
  },
  mounted() {
    if (this.modus === 'fuerdich') this.laden()
  },
  methods: {
    async laden() {
      this.laedt = true
      this.fehler = ''
      try {
        const r = await buecherApi(this, 'GET', '/buecher/seite')
        this.reihen = r.reihen || []
      } catch (e) {
        this.fehler = `Empfehlungen nicht geladen: ${e.message}`
      }
      this.laedt = false
    },
    async suchen() {
      const q = this.q.trim()
      if (!q) return this.leer()
      this.gesucht = true
      document.activeElement?.blur()
      this.laedt = true
      this.fehler = ''
      try {
        const r = await buecherApi(this, 'GET', '/buecher/suche?q=' + encodeURIComponent(q) + '&sprache=' + this.spracheWahl)
        this.reihen = r.eintraege?.length ? [{ titel: r.titel, eintraege: r.eintraege }] : []
      } catch (e) {
        this.fehler = `Suche fehlgeschlagen: ${e.message}`
      }
      this.laedt = false
    },
    spracheAendern(wert) {
      this.spracheWahl = wert
      spracheSetzen(wert)
      if (this.q.trim()) this.suchen()
    },
    leer() {
      if (this.q) return
      this.gesucht = false
      if (this.modus === 'fuerdich') this.laden()
    },
    modusAendern(m) {
      this.modus = m
      try {
        localStorage.setItem('hlb-modus', m)
      } catch (e) {}
      this.q = ''
      this.gesucht = false
      if (m === 'fuerdich') this.laden()
    },
    oeffnen(e) {
      this.auswahl = e
      this.zeigeDetails = true
    },
    markieren(e, art) {
      for (const r of this.reihen)
        for (const x of r.eintraege)
          if (x.provider === e.provider && x.book_id === e.book_id) {
            if (x.status !== 'vorhanden') x.status = 'angefragt'
            x.gewuenscht = [...new Set([...(x.gewuenscht || []), art])]
          }
    },
    async ablehnen(e) {
      try {
        await buecherApi(this, 'POST', '/buecher/ablehnen', { provider: e.provider, book_id: e.book_id, titel: e.titel })
        for (const r of this.reihen) r.eintraege = r.eintraege.filter((x) => !(x.provider === e.provider && x.book_id === e.book_id))
        this.$toast.info(`«${e.titel}» kommt nicht mehr`)
      } catch (err) {
        this.$toast.error(err.message)
      }
    }
  }
}
</script>
