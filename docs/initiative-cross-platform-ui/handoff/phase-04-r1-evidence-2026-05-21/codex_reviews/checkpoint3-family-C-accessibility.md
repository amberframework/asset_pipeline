   403	      # Screenshot only when axe is running (audits/screenshots are paired
   404	      # in the rubric on the axe-clean check; ibm is structured-data only).
   405	      if axe_source
   406	        shot = dt.screenshot_png
   407	        name = "#{File.basename(page_path, ".html")}-#{c[:label]}.png"
   408	        rel = write_artifact_png(name, shot)
   409	        screenshots << rel
   410	      end

 succeeded in 0ms:
  1166	  # Family C — Cross-cutting accessibility (axe + IBM on context-menu page)
  1167	  # ----------------------------------------------------------------
  1168	
  1169	  if run?("fallback.context-menu-axe-clean")
  1170	    log "probe: fallback.context-menu-axe-clean"
  1171	    out = matrix_audit(client, PAGES["context_menu"],
  1172	      axe_source: axe_source,
  1173	      open_helper: CTX_OPEN_HELPER)
  1174	    passed = out[:failures].empty?
  1175	    record = {
  1176	      "check_id" => "fallback.context-menu-axe-clean",
  1177	      "page" => "samples/cross_platform/web/dist/phase04_context_menu_demo.html",
  1178	      "selectors" => [".ap-ctx-menu[data-presented=true]"],
  1179	      "cdp_methods" => ["Runtime.evaluate (axe-core 4.10.2)", "Runtime.evaluate (axe.run)", "Page.captureScreenshot"],
  1180	      "trusted_input_trace" => ["trigger.focus + dispatchEvent('contextmenu') @ center", "axe.run(document)"],
  1181	      "expected_state" => {"serious_or_critical_violation_count_total" => 0},
  1182	      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
  1183	      "pass" => passed,
  1184	      "artifacts" => out[:screenshots] + ["audits/fallback.context-menu-axe-clean.json"],
  1185	    }
  1186	    write_record(audits_dir, "fallback.context-menu-axe-clean", record)
  1187	    any_failed = true unless passed
  1188	  end
  1189	
  1190	  if run?("fallback.context-menu-ibm-equal-access-clean")
  1191	    log "probe: fallback.context-menu-ibm-equal-access-clean"
  1192	    out = matrix_audit(client, PAGES["context_menu"],
  1193	      ace_source: ace_source,
  1194	      open_helper: CTX_OPEN_HELPER)
  1195	    passed = out[:failures].empty?
  1196	    record = {
  1197	      "check_id" => "fallback.context-menu-ibm-equal-access-clean",
  1198	      "page" => "samples/cross_platform/web/dist/phase04_context_menu_demo.html",
  1199	      "selectors" => [".ap-ctx-menu[data-presented=true]"],
  1200	      "cdp_methods" => ["Runtime.evaluate (accessibility-checker-engine 4.0.17)", "Runtime.evaluate (ace.Checker.check)"],
  1201	      "trusted_input_trace" => ["trigger.focus + dispatchEvent('contextmenu') @ center", "ace.Checker.check(document, ['IBM_Accessibility'])"],
  1202	      "expected_state" => {"violation_count_total" => 0},
  1203	      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
  1204	      "pass" => passed,
  1205	      "artifacts" => ["audits/fallback.context-menu-ibm-equal-access-clean.json"],
  1206	    }
  1207	    write_record(audits_dir, "fallback.context-menu-ibm-equal-access-clean", record)
  1208	    any_failed = true unless passed
  1209	  end
  1210	
  1211	  # Optional but valuable: PathControl page axe / IBM too. Not in the 12-check
  1212	  # routing table — provided here for the path-control family's evidence.
  1213	  if run?("fallback.path-control-axe-clean")
  1214	    log "probe: fallback.path-control-axe-clean (supplementary)"
  1215	    out = matrix_audit(client, PAGES["path_control"], axe_source: axe_source)
  1216	    write_record(audits_dir, "fallback.path-control-axe-clean", {
  1217	      "check_id" => "fallback.path-control-axe-clean",
  1218	      "page" => "samples/cross_platform/web/dist/phase04_path_control_demo.html",
  1219	      "selectors" => ["nav[aria-label=Breadcrumb]", "ol > li", "[aria-current=page]"],
  1220	      "cdp_methods" => ["Runtime.evaluate (axe-core 4.10.2)", "Runtime.evaluate (axe.run)"],
  1221	      "trusted_input_trace" => ["Page.navigate (file://)", "axe.run(document)"],
  1222	      "expected_state" => {"serious_or_critical_violation_count_total" => 0},
  1223	      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
  1224	      "pass" => out[:failures].empty?,
  1225	      "artifacts" => out[:screenshots] + ["audits/fallback.path-control-axe-clean.json"],
  1226	    })
  1227	  end
  1228	
  1229	  if run?("fallback.path-control-ibm-equal-access-clean")
  1230	    log "probe: fallback.path-control-ibm-equal-access-clean (supplementary)"
  1231	    out = matrix_audit(client, PAGES["path_control"], ace_source: ace_source)
  1232	    write_record(audits_dir, "fallback.path-control-ibm-equal-access-clean", {
  1233	      "check_id" => "fallback.path-control-ibm-equal-access-clean",
  1234	      "page" => "samples/cross_platform/web/dist/phase04_path_control_demo.html",
  1235	      "selectors" => ["nav[aria-label=Breadcrumb]"],
  1236	      "cdp_methods" => ["Runtime.evaluate (accessibility-checker-engine 4.0.17)", "Runtime.evaluate (ace.Checker.check)"],
  1237	      "trusted_input_trace" => ["Page.navigate (file://)", "ace.Checker.check(document)"],
  1238	      "expected_state" => {"violation_count_total" => 0},
  1239	      "observed_state" => {"results" => out[:results], "failures" => out[:failures]},
  1240	      "pass" => out[:failures].empty?,
  1241	      "artifacts" => ["audits/fallback.path-control-ibm-equal-access-clean.json"],
  1242	    })
  1243	  end
  1244	
  1245	  log "DONE. any_failed=#{any_failed}"

codex
**Verdict**

Mostly yes, with one wording/evidence problem.

`fallback.context-menu-axe-clean` is sufficient for the axe-clean rubric. The harness opens the menu with `CTX_OPEN_HELPER`, then runs `axe.run(document)` across 4 viewport/scheme cases. Axe does not need menu interactions to be wired in order to audit the currently open DOM; it is a static/runtime DOM audit at that moment. It will not prove keyboard behavior. That proof belongs to the separate focus/context-menu checks. The record would be stronger if it captured `menu_presented: true`, item count, and active element before running axe, but the PASS is not invalid.

`fallback.context-menu-ibm-equal-access-clean` is only a PASS under the repo’s existing “hard IBM failure” convention: `value[0] == "VIOLATION" && value[1] == "FAIL"` in [scripts/phase04_cdp_harness.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/scripts/phase04_cdp_harness.cr:383). It is not accurate to call this “zero violation-level findings.” The JSON has `VIOLATION/POTENTIAL` and `VIOLATION/MANUAL`, including menu-specific keyboard/tabbable findings in [fallback.context-menu-ibm-equal-access-clean.json](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/audits/fallback.context-menu-ibm-equal-access-clean.json:85). Those do not automatically fail if the convention is hard-fail only, but they must be disclosed and adjudicated against the separate keyboard evidence.

The two PathControl supplementary checks are acceptable as supplementary evidence. PathControl is static breadcrumb semantics, and the axe record shows zero violations/incomplete across all 4 cases in [fallback.path-control-axe-clean.json](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/audits/fallback.path-control-axe-clean.json:20). The IBM record has hard-fail count zero, and its active findings are generic style/skip-link potentials, not breadcrumb-specific failures.

So the one check I’d mark “PASS but insufficient/misleading as written” is `fallback.context-menu-ibm-equal-access-clean` if the report says “zero violation-level findings.” Safer wording: “zero IBM `VIOLATION/FAIL` hard failures; `POTENTIAL`/`MANUAL` findings retained and reviewed; menu keyboard potentials covered by the separate behavior probe.”


tokens used
137,025
**Verdict**

Mostly yes, with one wording/evidence problem.

`fallback.context-menu-axe-clean` is sufficient for the axe-clean rubric. The harness opens the menu with `CTX_OPEN_HELPER`, then runs `axe.run(document)` across 4 viewport/scheme cases. Axe does not need menu interactions to be wired in order to audit the currently open DOM; it is a static/runtime DOM audit at that moment. It will not prove keyboard behavior. That proof belongs to the separate focus/context-menu checks. The record would be stronger if it captured `menu_presented: true`, item count, and active element before running axe, but the PASS is not invalid.

`fallback.context-menu-ibm-equal-access-clean` is only a PASS under the repo’s existing “hard IBM failure” convention: `value[0] == "VIOLATION" && value[1] == "FAIL"` in [scripts/phase04_cdp_harness.cr](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/scripts/phase04_cdp_harness.cr:383). It is not accurate to call this “zero violation-level findings.” The JSON has `VIOLATION/POTENTIAL` and `VIOLATION/MANUAL`, including menu-specific keyboard/tabbable findings in [fallback.context-menu-ibm-equal-access-clean.json](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/audits/fallback.context-menu-ibm-equal-access-clean.json:85). Those do not automatically fail if the convention is hard-fail only, but they must be disclosed and adjudicated against the separate keyboard evidence.

The two PathControl supplementary checks are acceptable as supplementary evidence. PathControl is static breadcrumb semantics, and the axe record shows zero violations/incomplete across all 4 cases in [fallback.path-control-axe-clean.json](/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/handoff/phase-04-r1-evidence-2026-05-21/audits/fallback.path-control-axe-clean.json:20). The IBM record has hard-fail count zero, and its active findings are generic style/skip-link potentials, not breadcrumb-specific failures.

So the one check I’d mark “PASS but insufficient/misleading as written” is `fallback.context-menu-ibm-equal-access-clean` if the report says “zero violation-level findings.” Safer wording: “zero IBM `VIOLATION/FAIL` hard failures; `POTENTIAL`/`MANUAL` findings retained and reviewed; menu keyboard potentials covered by the separate behavior probe.”


