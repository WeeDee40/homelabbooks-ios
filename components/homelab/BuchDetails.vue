<template>
  <modals-modal v-model="zeigen" :width="420" height="100%">
    <div v-if="eintrag" class="w-full h-full overflow-y-auto pt-24 pb-10 px-2" @click.self="zeigen = false">
      <div class="bg-bg rounded-lg p-4 shadow-lg">
        <div class="flex gap-4">
          <img v-if="eintrag.cover" :src="eintrag.cover" class="w-24 h-36 object-cover rounded-md flex-none shadow" />
          <div class="min-w-0">
            <p class="text-lg font-semibold leading-tight">{{ eintrag.titel }}</p>
            <p class="text-sm text-fg-muted mt-1">{{ eintrag.autor }}</p>
            <p v-if="eintrag.reihe" class="text-xs text-fg-muted mt-1">{{ eintrag.reihe }}<span v-if="eintrag.band">, Band {{ eintrag.band }}</span></p>
            <p v-if="eintrag.jahr" class="text-xs text-fg-muted">{{ eintrag.jahr }}</p>
            <p v-if="eintrag.weil" class="text-xs text-fg-muted mt-1">Weil du «{{ eintrag.weil }}» kennst</p>
          </div>
        </div>
        <p v-if="eintrag.beschreibung" class="text-sm mt-4 whitespace-pre-line text-fg/90">{{ eintrag.beschreibung }}</p>
        <div class="mt-5 flex flex-col gap-2">
          <template v-if="eintrag.status === 'vorhanden'">
            <ui-btn color="success" @click="zuAudiobookshelf">Ansehen ({{ (eintrag.formate || []).join(' · ') || 'in der Bibliothek' }})</ui-btn>
          </template>
          <template v-else-if="gewuenscht || eintrag.status === 'angefragt'">
            <p class="text-sm text-center text-fg-muted py-2">Ist gewünscht. Sobald es freigegeben und geladen ist, steht es in der Bibliothek.</p>
          </template>
          <template v-else>
            <ui-btn color="success" :loading="laeuft === 'audiobook'" :disabled="!!laeuft" @click="wuenschen('audiobook')">Hörbuch wünschen</ui-btn>
            <ui-btn color="primary" :loading="laeuft === 'ebook'" :disabled="!!laeuft" @click="wuenschen('ebook')">E-Book wünschen</ui-btn>
          </template>
        </div>
      </div>
    </div>
  </modals-modal>
</template>

<script>
// HomeLabBooks: Detailfenster im Tab «Entdecken» (Beschreibung, Wünschen als Hörbuch oder E-Book)
import { buecherApi, sprache } from '~/homelab/buecher-api'

export default {
  props: { value: Boolean, eintrag: Object },
  data() {
    return { laeuft: null, gewuenscht: false }
  },
  watch: {
    eintrag() {
      this.gewuenscht = false
    }
  },
  computed: {
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
    zuAudiobookshelf() {
      this.zeigen = false
      this.$router.push(`/item/${this.eintrag.abs_id}`)
    },
    async wuenschen(art) {
      this.laeuft = art
      try {
        const r = await buecherApi(this, 'POST', '/buecher/wunsch', { provider: this.eintrag.provider, book_id: this.eintrag.book_id, content_type: art, titel: this.eintrag.titel, sprache: sprache() })
        this.gewuenscht = true
        this.$emit('gewuenscht', this.eintrag)
        this.$toast.success(r.meldung || 'Gewünscht')
      } catch (e) {
        this.$toast.error(`Wunsch fehlgeschlagen: ${e.message}`)
      }
      this.laeuft = null
    }
  }
}
</script>
