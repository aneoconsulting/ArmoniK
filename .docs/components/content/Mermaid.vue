<script setup lang="ts">
// Need to duplicate component from template because of an import issue.
import mermaid from "mermaid"

const show = ref(false);

onMounted(async () => {
  show.value = true
  mermaid.initialize({ startOnLoad: true })
  await nextTick()
  mermaid.init();
})

</script>

<template>
  <div v-if="show" class="mermaid">
    <slot/>
  </div>
</template>
