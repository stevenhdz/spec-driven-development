---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs,py,go,rs,java,kt,kts,scala,rb,php,cs,swift,dart,vue,svelte,astro}"
---
# Architecture Rules
<!-- Spec Driven Development by stevenhdz · https://github.com/stevenhdz/spec-driven-development — framework file: `install.sh --update` overwrites it. Your own path rules go in other files of .claude/rules/. -->

- `.claude/project.md` → Layer Structure defines the modules and layers — where it differs from a rule below, it wins
- Import another module only through its public API — never its internal files
- Keep business rules out of the entry layer — extract them to the logic layer
- Keep the transport (DOM, HTTP, terminal) out of the logic layer — it takes and returns plain data
- Check the shape of external data (parsed JSON, request body, file content) in the entry layer — data of the wrong shape becomes the error path, never an unhandled exception
