<template>
  <div class="flex-none w-28 flex flex-col">
    <div class="relative w-28 h-40 rounded-md overflow-hidden bg-secondary shadow-md" @click="$emit('oeffnen', eintrag)">
      <img v-if="coverUrl" :src="coverUrl" class="w-full h-full object-cover" loading="lazy" @error="coverIndex++" />
      <!-- ohne Cover: schlichter «Buchumschlag» mit Haupttitel und Autor statt des langen Katalogtitels -->
      <div v-else class="w-full h-full flex flex-col justify-between p-2.5 text-left bg-gradient-to-br from-slate-600 to-slate-800">
        <span class="material-symbols text-lg text-white/60">menu_book</span>
        <div>
          <p class="text-[13px] font-semibold leading-tight text-white line-clamp-4">{{ haupttitel }}</p>
          <p class="text-[10px] text-white/70 mt-1 truncate">{{ eintrag.autor }}</p>
        </div>
      </div>
      <span v-if="marke" class="absolute top-1 left-1 text-[10px] px-1.5 py-0.5 rounded-full text-white" :class="eintrag.status === 'vorhanden' ? 'bg-success' : 'bg-warning'">{{ marke }}</span>
      <button v-if="eintrag.status !== 'vorhanden'" class="absolute top-1 right-1 w-6 h-6 rounded-full bg-black/60 text-white flex items-center justify-center" @click.stop="$emit('ablehnen', eintrag)">
        <span class="material-symbols text-sm">close</span>
      </button>
    </div>
    <p class="text-sm leading-tight mt-1 line-clamp-2 min-h-[2.5em]">{{ eintrag.titel }}</p>
    <p class="text-xs text-fg-muted truncate">{{ eintrag.autor }}</p>
  </div>
</template>

<script>
// HomeLabBooks: Karte im Tab «Entdecken»
export default {
  props: { eintrag: { type: Object, required: true } },
  data() {
    return { coverIndex: 0 } // Cover aus mehreren Quellen (DNB, Open Library); fehlt eines, das nächste
  },
  computed: {
    haupttitel() {
      return (this.eintrag.titel || '').split(/\s*[:–—]\s|\s-\s/)[0]
    },
    coverUrl() {
      const liste = this.eintrag.covers || (this.eintrag.cover ? [this.eintrag.cover] : [])
      return liste[this.coverIndex] || null
    },
    marke() {
      if (this.eintrag.status === 'vorhanden') return this.eintrag.formate?.length ? this.eintrag.formate.join(' · ') : 'Schon da'
      if (this.eintrag.status === 'angefragt') return 'Gewünscht'
      return ''
    }
  }
}
</script>
