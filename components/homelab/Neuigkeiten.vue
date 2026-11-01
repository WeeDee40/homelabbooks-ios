<template>
  <modals-modal v-model="zeigen" :width="420" height="100%">
    <div class="w-full h-full overflow-y-auto pt-24 pb-10 px-2" @click.self="zeigen = false">
      <div class="bg-bg rounded-lg p-4 shadow-lg">
        <p class="text-lg font-semibold">Neu in dieser Version</p>
        <div v-for="e in eintraege" :key="e.id" class="mt-4">
          <p class="text-xs uppercase font-semibold text-fg-muted">{{ datum(e.id) }}</p>
          <div v-for="g in e.gruppen" :key="g.titel" class="mt-2">
            <p class="font-semibold">{{ g.titel }}</p>
            <p v-for="p in g.punkte" :key="p" class="text-sm mt-1">• {{ p }}</p>
          </div>
        </div>
        <ui-btn class="w-full mt-5" color="success" @click="zeigen = false">Fertig</ui-btn>
      </div>
    </div>
  </modals-modal>
</template>

<script>
// HomeLabBooks: «Neu in dieser Version» aus static/neuigkeiten.md, die das Upload-Skript auch an TestFlight schickt.
// Einträge: `## 2026-11-01` (zweiter am selben Tag: `## 2026-11-01b`), `### Neu|Anders|Behoben`, `- kurzer Satz`.
import { Preferences } from '@capacitor/preferences'

const SCHLUESSEL = 'neuigkeiten.gesehen'

export default {
  data() {
    return {
      zeigen: false,
      alle: [],
      eintraege: []
    }
  },
  watch: {
    zeigen(offen) {
      if (!offen && this.alle.length) Preferences.set({ key: SCHLUESSEL, value: this.alle[0].id })
    }
  },
  methods: {
    lesen(text) {
      const eintraege = []
      for (const zeile of text.split('\n')) {
        const letzter = eintraege[eintraege.length - 1]
        if (zeile.startsWith('### ') && letzter) letzter.gruppen.push({ titel: zeile.slice(4).trim(), punkte: [] })
        else if (zeile.startsWith('## ')) eintraege.push({ id: zeile.slice(3).trim(), gruppen: [] })
        else if (zeile.startsWith('- ') && letzter?.gruppen.length) letzter.gruppen[letzter.gruppen.length - 1].punkte.push(zeile.slice(2).trim())
      }
      return eintraege
    },
    async laden() {
      if (!this.alle.length) {
        const antwort = await fetch('/neuigkeiten.md')
        this.alle = this.lesen(await antwort.text())
      }
      return this.alle
    },
    /** Noch nie etwas gezeigt: Neu installiert sieht nichts, wer von einer Version ohne dieses Fenster kommt, den neuesten Eintrag. */
    async pruefen(angemeldet) {
      try {
        const alle = await this.laden()
        if (!alle.length) return
        const { value: gesehen } = await Preferences.get({ key: SCHLUESSEL })
        if (!gesehen && !angemeldet) {
          await Preferences.set({ key: SCHLUESSEL, value: alle[0].id })
          return
        }
        this.eintraege = gesehen ? alle.filter((e) => e.id > gesehen) : alle.slice(0, 1)
        this.zeigen = this.eintraege.length > 0
      } catch (error) {
        console.error('[Neuigkeiten]', error)
      }
    },
    async alleZeigen() {
      this.eintraege = await this.laden()
      this.zeigen = true
    },
    datum(id) {
      return new Date(id.slice(0, 10) + 'T12:00:00').toLocaleDateString('de-CH', { day: 'numeric', month: 'long', year: 'numeric' })
    }
  },
  mounted() {
    this.$eventBus.$on('neuigkeiten-zeigen', this.alleZeigen)
  },
  beforeDestroy() {
    this.$eventBus.$off('neuigkeiten-zeigen', this.alleZeigen)
  }
}
</script>
