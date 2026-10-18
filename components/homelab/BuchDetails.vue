<template>
  <modals-modal v-model="zeigen" :width="420" height="100%">
    <div v-if="eintrag" class="w-full h-full overflow-y-auto pt-24 pb-10 px-2" @click.self="zeigen = false">
      <div class="bg-bg rounded-lg p-4 shadow-lg">
        <div class="flex gap-4">
          <img v-if="coverUrl" :src="coverUrl" class="w-24 h-36 object-cover rounded-md flex-none shadow" @error="coverFehler" />
          <div v-else class="w-24 h-36 rounded-md flex-none bg-secondary flex items-center justify-center"><span class="material-symbols text-3xl text-fg-muted">menu_book</span></div>
          <div class="min-w-0">
            <p class="text-lg font-semibold leading-tight">{{ eintrag.titel }}</p>
            <p class="text-sm text-fg-muted mt-1">{{ eintrag.autor }}</p>
            <p v-if="reihe" class="text-xs text-fg-muted mt-1">{{ reihe }}<span v-if="band">, Band {{ band }}</span></p>
            <p v-if="eintrag.info" class="text-xs text-fg-muted mt-1">{{ eintrag.info }}</p>
            <p v-else-if="eintrag.jahr" class="text-xs text-fg-muted">{{ eintrag.jahr }}</p>
            <div v-if="eintrag.themen && eintrag.themen.length" class="flex flex-wrap gap-1 mt-2">
              <span v-for="th in eintrag.themen" :key="th" class="text-[10px] px-2 py-0.5 rounded-full bg-secondary text-fg-muted">{{ th }}</span>
            </div>
            <p v-if="eintrag.weil" class="text-xs text-fg-muted mt-1">Weil du «{{ eintrag.weil }}» kennst</p>
          </div>
        </div>
        <p v-if="beschreibung" class="text-sm mt-4 whitespace-pre-line text-fg/90">{{ beschreibung }}</p>
        <p v-else-if="detailsLaden" class="text-sm mt-4 text-fg-muted">Beschreibung wird geladen …</p>
        <p v-if="quelle" class="text-[10px] mt-1 text-fg-muted">Beschreibung: {{ quelle }}</p>
        <div class="mt-5 flex flex-col gap-2">
          <ui-btn v-if="eintrag.abs_id" color="success" @click="zuAudiobookshelf">In der Bibliothek ansehen</ui-btn>
          <!-- pro Format: schon da, lädt gerade oder wünschen (so lässt sich das andere Format nachträglich wünschen) -->
          <template v-for="f in formate">
            <p v-if="f.stand" :key="f.art" class="text-sm text-fg-muted flex items-center justify-center gap-1 py-2">
              <span class="material-symbols text-base">{{ f.stand === 'da' ? 'check_circle' : 'downloading' }}</span>
              {{ f.text }} {{ f.stand === 'da' ? 'ist in der Bibliothek' : 'wird geladen' }}
            </p>
            <ui-btn v-else :key="f.art" :color="f.art === 'audiobook' ? 'success' : 'primary'" :loading="laeuft === f.art" :disabled="!!laeuft" @click="wuenschen(f.art)">{{ f.text }} wünschen</ui-btn>
          </template>
        </div>
      </div>
    </div>
  </modals-modal>
</template>

<script>
// HomeLabBooks: Detailfenster im Tab «Entdecken» (Beschreibung, Wünschen als Hörbuch oder E-Book)
import { buecherApi, sprache, coverUrl } from '~/homelab/buecher-api'

export default {
  props: { value: Boolean, eintrag: Object },
  data() {
    return { laeuft: null, gewuenschtLokal: [], details: null, detailsLaden: false, coverIndex: 0 }
  },
  watch: {
    eintrag() {
      this.gewuenschtLokal = []
      this.details = null
      this.coverIndex = 0
      this.detailsHolen()
    }
  },
  computed: {
    // Cover aus mehreren Quellen: DNB-Cover-Dienst, Open Library, Hardcover (aus den Details); fehlt eines, das nächste
    coverListe() {
      const e = this.eintrag || {}
      const bib = e.abs_id ? [this.$store.getters['globals/getLibraryItemCoverSrcById'](e.abs_id)] : [] // wie in der Bibliothek
      return [...bib, ...(e.covers || (e.cover ? [e.cover] : [])), this.details?.cover].filter(Boolean)
    },
    coverUrl() {
      return coverUrl(this.$store, this.coverListe[this.coverIndex]) || null
    },
    beschreibung() {
      return this.details?.beschreibung || this.eintrag?.beschreibung || ''
    },
    quelle() {
      return this.details?.beschreibung ? this.details.quelle : null
    },
    reihe() {
      return this.eintrag?.reihe || this.details?.reihe
    },
    band() {
      return this.eintrag?.band || this.details?.band
    },
    formate() {
      const e = this.eintrag || {}
      return [
        { art: 'audiobook', text: 'Hörbuch', name: 'Hörbuch' },
        { art: 'ebook', text: 'E-Book', name: 'E-Book' }
      ].map((f) => ({
        ...f,
        stand: (e.formate || []).includes(f.name) ? 'da' : (e.gewuenscht || []).includes(f.art) || this.gewuenschtLokal.includes(f.art) ? 'laedt' : null
      }))
    },
    zeigen: {
      get() {
        return this.value
      },
      set(v) {
        this.$emit('input', v)
      }
    }
  },
  methods: {
    coverFehler() {
      this.coverIndex++
    },
    async detailsHolen() {
      const e = this.eintrag
      if (!e || e.provider === 'manual') return
      this.detailsLaden = true
      try {
        const q = new URLSearchParams({ provider: e.provider, book_id: e.book_id, idn: e.idn || '', titel: e.titel || '', autor: e.autor || '' })
        const d = await buecherApi(this, 'GET', '/buecher/details?' + q.toString())
        if (this.eintrag === e) this.details = d
      } catch (err) {
        console.warn('[HomeLabBooks] Details nicht geladen', err)
      }
      this.detailsLaden = false
    },
    zuAudiobookshelf() {
      this.zeigen = false
      this.$router.push(`/item/${this.eintrag.abs_id}`)
    },
    async wuenschen(art) {
      this.laeuft = art
      try {
        const r = await buecherApi(this, 'POST', '/buecher/wunsch', { provider: this.eintrag.provider, book_id: this.eintrag.book_id, content_type: art, titel: this.eintrag.titel, autor: this.eintrag.autor, sprache: sprache() })
        this.gewuenschtLokal.push(art)
        this.$emit('gewuenscht', this.eintrag, art)
        this.$toast.success(r.meldung || 'Gewünscht')
      } catch (e) {
        this.$toast.error(`Wunsch fehlgeschlagen: ${e.message}`)
      }
      this.laeuft = null
    }
  }
}
</script>
