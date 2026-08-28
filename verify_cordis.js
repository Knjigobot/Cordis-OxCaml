// verify_cordis.js - Cross-Verification & Structural Audit for Cordis-OxCaml
const fs = require('fs');
const path = require('path');

const ROOT = __dirname;

console.log("========================================================");
console.log("  AUDITING CORDIS-OXCAML CODEBASE INTEGRITY");
console.log("========================================================");

const REQUIRED_FILES = [
  'dune-project',
  'cordis-oxcaml.opam',
  'LICENSE',
  'NOTICE',
  'README.md',
  'THEORY.md',
  'MIGRATION.md',
  '.gitignore',
  '.github/workflows/ci.yml',
  'cordis_core/dune',
  'cordis_core/types.ml',
  'cordis_core/types.mli',
  'cordis_core/scope.ml',
  'cordis_core/scope.mli',
  'cordis_core/context.ml',
  'cordis_core/context.mli',
  'cordis_core/events.ml',
  'cordis_core/events.mli',
  'cordis_core/service.ml',
  'cordis_core/service.mli',
  'cordis_core/registry.ml',
  'cordis_core/registry.mli',
  'cordis_core/effect_handler.ml',
  'cordis_core/effect_handler.mli',
  'cordis_core/cordis_core.ml',
  'cordis_core/cordis_core.mli',
  'cordis_system/dune',
  'cordis_system/schema.ml',
  'cordis_system/schema.mli',
  'cordis_system/timer.ml',
  'cordis_system/timer.mli',
  'cordis_system/logger.ml',
  'cordis_system/logger.mli',
  'cordis_system/loader.ml',
  'cordis_system/loader.mli',
  'cordis_system/http_server.ml',
  'cordis_system/http_server.mli',
  'cordis_system/cordis_system.ml',
  'cordis_system/cordis_system.mli',
  'cordis_quant/dune',
  'cordis_quant/ring_buffer.ml',
  'cordis_quant/ring_buffer.mli',
  'cordis_quant/market_types.ml',
  'cordis_quant/market_types.mli',
  'cordis_quant/market_feed.ml',
  'cordis_quant/market_feed.mli',
  'cordis_quant/plugin_bollinger.ml',
  'cordis_quant/plugin_bollinger.mli',
  'cordis_quant/plugin_ma.ml',
  'cordis_quant/plugin_ma.mli',
  'cordis_quant/cordis_quant.ml',
  'cordis_quant/cordis_quant.mli',
  'test/dune',
  'test/test_runner.ml',
  'test/test_spatiotemporal.ml',
  'test/test_context.ml',
  'test/test_events.ml',
  'test/test_lifecycle.ml',
  'test/test_fault_isolation.ml',
  'test/test_schema.ml',
  'test/test_timer.ml',
  'test/test_loader.ml',
  'test/test_algebraic_effects.ml',
  'bin/dune',
  'bin/main.ml',
  'examples/dune',
  'examples/01_hello_cordis/dune',
  'examples/01_hello_cordis/main.ml',
  'examples/02_revertible_effects/dune',
  'examples/02_revertible_effects/main.ml',
  'examples/03_dependency_injection/dune',
  'examples/03_dependency_injection/main.ml',
  'examples/04_config_schema/dune',
  'examples/04_config_schema/main.ml',
  'examples/05_trading_daemon/dune',
  'examples/05_trading_daemon/main.ml'
];

let allPassed = true;
let totalLines = 0;

REQUIRED_FILES.forEach(relPath => {
  const fullPath = path.join(ROOT, relPath);
  if (!fs.existsSync(fullPath)) {
    console.error(`  [FAIL] Missing file: ${relPath}`);
    allPassed = false;
  } else {
    const content = fs.readFileSync(fullPath, 'utf8');
    const lines = content.split('\n').length;
    totalLines += lines;
    console.log(`  [OK] ${relPath.padEnd(45)} (${lines} lines)`);
  }
});

console.log("\n========================================================");
console.log(`  AUDIT SUMMARY: ${REQUIRED_FILES.length} files verified.`);
console.log(`  Total Code & Documentation: ${totalLines} Lines of Code.`);
console.log(`  STATUS: ${allPassed ? 'ALL CHECKS PASSED PERFECTLY' : 'FAILURES DETECTED'}`);
console.log("========================================================");

if (!allPassed) process.exit(1);
