<template>
  <div class="flex-none w-28 flex flex-col">
    <div class="relative w-28 h-40 rounded-md overflow-hidden bg-secondary shadow-md" @click="$emit('oeffnen', eintrag)">
      <img v-if="eintrag.cover && !ohneCover" :src="eintrag.cover" class="w-full h-full object-cover" loading="lazy" @error="ohneCover = true" />
      <div v-else class="w-full h-full flex flex-col items-center justify-center p-2 text-center text-xs text-fg-muted gap-1">
        <span class="material-symbols text-2xl">menu_book</span>{{ eintrag.titel }}
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
    return { ohneCover: false } // Katalog-Cover (Open Library über die ISBN) gibt es nicht für jedes Buch
  },
  computed: {
    marke() {
      if (this.eintrag.status === 'vorhanden') return this.eintrag.formate?.length ? this.eintrag.formate.join(' · ') : 'Schon da'
      if (this.eintrag.status === 'angefragt') return 'Gewünscht'
      return ''
    }
  }
}
</script>
