<script setup lang="ts">
// Need to duplicate component from template because of an import issue.
import mermaid from "mermaid"

let show = ref(false);

onMounted(async () => {
  show.value = true
  mermaid.initialize({ startOnLoad: true })
  await nextTick()
  mermaid.init();
})

</script>

<template>
  <div class="mermaid" v-if="show">
    <slot></slot>
  </div>
</template>
