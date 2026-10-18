<template>
  <div>
    <!-- Oberkategorien -->
    <div class="flex gap-2 overflow-x-auto px-4 pt-3 no-scroll">
      <button v-for="k in kategorien" :key="k.id" type="button" class="flex-none text-sm px-3 py-1.5 rounded-full border"
        :class="ober && ober.id === k.id ? 'bg-fg text-bg border-fg' : 'border-border text-fg-muted'" @click="waehleOber(k)">{{ k.name }}</button>
    </div>
    <!-- Unterkategorien -->
    <div v-if="ober" class="flex gap-2 overflow-x-auto px-4 pt-2 no-scroll">
      <button v-for="u in ober.unter" :key="u.id" type="button" class="flex-none text-xs px-3 py-1 rounded-full"
        :class="unter === u.id ? 'bg-primary text-fg font-semibold' : 'bg-secondary text-fg-muted'" @click="waehleUnter(u.id)">{{ u.name }}</button>
    </div>
    <!-- Filter -->
    <div class="flex items-center gap-2 px-4 pt-2 text-xs text-fg-muted">
      <span class="material-symbols text-base">tune</span>
      <button v-for="z in zeitraeume" :key="z.wert" type="button" class="px-2.5 py-0.5 rounded-full border"
        :class="zeitraum === z.wert ? 'border-fg text-fg' : 'border-border'" @click="zeitraumAendern(z.wert)">{{ z.text }}</button>
    </div>

    <div v-if="laedt" class="flex flex-col items-center justify-center py-16 text-fg-muted">
      <svg class="animate-spin mb-3" style="width: 28px; height: 28px" viewBox="0 0 24 24"><path fill="currentColor" d="M12,4V2A10,10 0 0,0 2,12H4A8,8 0 0,1 12,4Z" /></svg>
      <p class="text-sm">Stöbert in {{ unterName }} …</p>
    </div>
    <p v-else-if="fehler" class="px-4 py-10 text-center text-sm text-fg-muted">{{ fehler }}</p>
    <template v-else>
      <section v-for="reihe in reihen" :key="reihe.titel" class="mt-5">
        <h2 class="px-4 mb-2 text-base font-semibold">{{ reihe.titel }}</h2>
        <div class="flex gap-3 overflow-x-auto px-4 pb-1 no-scroll">
          <homelab-buch-karte v-for="e in reihe.eintraege" :key="e.provider + e.book_id" :eintrag="e" @oeffnen="$emit('oeffnen', $event)" @ablehnen="ablehnen(reihe, $event)" />
          <button v-if="reihe.mehr" type="button" class="flex-none w-28 h-40 rounded-md border border-dashed border-border text-fg-muted text-sm flex flex-col items-center justify-center gap-1" :disabled="mehrLaedt" @click="mehr(reihe)">
            <span class="material-symbols text-2xl">{{ mehrLaedt ? 'hourglass_empty' : 'arrow_forward' }}</span>Mehr
          </button>
        </div>
      </section>
      <p v-if="!reihen.length && unter" class="px-4 py-10 text-center text-sm text-fg-muted">In dieser Kategorie nichts gefunden.</p>
    </template>
  </div>
</template>

<script>
// HomeLabBooks: Stöbern nach Kategorien (Ober- und Unterkategorien, Filter, Reihen Beliebt / Neuheiten / Für dich)
import { buecherApi } from '~/homelab/buecher-api'

export default {
  props: { sprache: { type: String, default: 'de' } },
  data() {
    return {
      kategorien: [], ober: null, unter: null, zeitraum: 'alle', reihen: [], laedt: false, fehler: '', seite: 0, mehrLaedt: false,
      zeitraeume: [{ wert: 'alle', text: 'Alle Jahre' }, { wert: 'neu', text: 'Letzte 2 Jahre' }]
    }
  },
  computed: {
    unterName() {
      return (this.ober?.unter || []).find((u) => u.id === this.unter)?.name || ''
    }
  },
  watch: {
    sprache() {
      this.laden()
    }
  },
  async mounted() {
    try {
      this.kategorien = (await buecherApi(this, 'GET', '/buecher/kategorien')).kategorien || []
    } catch (e) {
      this.fehler = `Kategorien nicht geladen: ${e.message}`
      return
    }
    let gemerkt = null
    try {
      gemerkt = localStorage.getItem('hlb-kategorie')
      this.zeitraum = localStorage.getItem('hlb-zeitraum') === 'neu' ? 'neu' : 'alle'
    } catch (e) {}
    this.ober = this.kategorien.find((k) => k.unter.some((u) => u.id === gemerkt)) || this.kategorien[0]
    this.unter = gemerkt && this.ober.unter.some((u) => u.id === gemerkt) ? gemerkt : this.ober.unter[0].id
    this.laden()
  },
  methods: {
    merken() {
      try {
        localStorage.setItem('hlb-kategorie', this.unter)
        localStorage.setItem('hlb-zeitraum', this.zeitraum)
      } catch (e) {}
    },
    waehleOber(k) {
      this.ober = k
      this.waehleUnter(k.unter[0].id)
    },
    waehleUnter(id) {
      this.unter = id
      this.laden()
    },
    zeitraumAendern(wert) {
      this.zeitraum = wert
      this.laden()
    },
    async laden() {
      if (!this.unter) return
      this.merken()
      this.laedt = true
      this.fehler = ''
      this.seite = 0
      const id = this.unter
      try {
        const r = await buecherApi(this, 'GET', `/buecher/kategorie?id=${id}&zeitraum=${this.zeitraum}&sprache=${this.sprache}`)
        if (this.unter === id) this.reihen = r.reihen || []
      } catch (e) {
        this.fehler = `Nicht geladen: ${e.message}`
      }
      this.laedt = false
    },
    async mehr(reihe) {
      this.mehrLaedt = true
      try {
        const r = await buecherApi(this, 'GET', `/buecher/kategorie?id=${this.unter}&zeitraum=${this.zeitraum}&sprache=${this.sprache}&seite=${this.seite + 1}`)
        this.seite++
        reihe.eintraege = [...reihe.eintraege, ...(r.eintraege || [])]
        reihe.mehr = r.mehr
      } catch (e) {
        this.$toast.error(e.message)
      }
      this.mehrLaedt = false
    },
    async ablehnen(reihe, e) {
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
