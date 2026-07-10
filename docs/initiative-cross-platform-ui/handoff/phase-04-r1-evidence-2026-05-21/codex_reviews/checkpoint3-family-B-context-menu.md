    23	  },
    24	  "observed_state": {
    25	    "click_point": {
    26	      "x": 50.6015625,
    27	      "y": 22.0
    28	    },
    29	    "trigger_rect": {
    30	      "left": 0,
    31	      "top": 0,
    32	      "right": 101.203125,
    33	      "bottom": 44,
    34	      "width": 101.203125,
    35	      "height": 44
    36	    },
    37	    "menu_rect": {
    38	      "left": 50,
    39	      "top": 22,
    40	      "right": 260,
    41	      "bottom": 169,
    42	      "width": 210,
    43	      "height": 147
    44	    },
    45	    "viewport": {
    46	      "w": 1280,
    47	      "h": 800
    48	    },
    49	    "trigger_in_quadrant": true,
    50	    "on_screen": true,
    51	    "anchored_within_tolerance": true
    52	  },
    53	  "pass": true,
    54	  "artifacts": [
    55	    "inspections/conformance.context-menu-positioning-top-left.json"
    56	  ]
    57	}     1	{
     2	  "check_id": "conformance.context-menu-positioning-center",
     3	  "page": "samples/cross_platform/web/dist/phase04_context_menu_demo.html",
     4	  "selectors": [
     5	    "[data-testid=ctx-trigger-center]",
     6	    ".ap-ctx-menu"
     7	  ],
     8	  "cdp_methods": [
     9	    "Emulation.setDeviceMetricsOverride (1280x800)",
    10	    "Runtime.evaluate (rect capture)",
    11	    "Input.dispatchMouseEvent (right press/release at trigger center)",
    12	    "Runtime.evaluate (post-open rect capture)"
    13	  ],
    14	  "trusted_input_trace": [
    15	    "read trigger rect",
    16	    "right-mouseDown@(640.0,400.0)",
    17	    "right-mouseUp@(640.0,400.0)"
    18	  ],
    19	  "expected_state": {
    20	    "trigger_in_quadrant": true,
    21	    "menu_on_screen": true,
    22	    "menu_anchored_within_tolerance_or_repositioned": true
    23	  },
    24	  "observed_state": {
    25	    "click_point": {
    26	      "x": 640.0,
    27	      "y": 400.0
    28	    },
    29	    "trigger_rect": {
    30	      "left": 591.25,
    31	      "top": 378,
    32	      "right": 688.75,
    33	      "bottom": 422,
    34	      "width": 97.5,
    35	      "height": 44
    36	    },
    37	    "menu_rect": {
    38	      "left": 640,
    39	      "top": 400,
    40	      "right": 850,
    41	      "bottom": 547,
    42	      "width": 210,
    43	      "height": 147
    44	    },
    45	    "viewport": {
    46	      "w": 1280,
    47	      "h": 800
    48	    },
    49	    "trigger_in_quadrant": true,
    50	    "on_screen": true,
    51	    "anchored_within_tolerance": true
    52	  },
    53	  "pass": true,
    54	  "artifacts": [
    55	    "inspections/conformance.context-menu-positioning-center.json"
    56	  ]
    57	}
codex
No, I would not treat the PASS labels alone as fully proven for all three.

`focus.context-menu-outside-click-closes` looks sufficient. The record proves the menu was open, the click point was outside the menu rect, `data-presented` became `"false"`, dismiss reason was `"outside"`, and focus returned to `ctx-trigger-center`.

`focus.context-menu-keyboard-nav` is behaviorally convincing, and the six-key transcript is the right shape. The rubric asks for activeElement after `ArrowDown, ArrowDown, ArrowUp, Home, End, Escape`; this record has that plus the open state. I do not think it needs more per-key captures. The gap is that the JSON does not prove the disabled fixture/order independently. It should include a static menu item snapshot like `Open enabled`, `Rename enabled`, `Duplicate aria-disabled/data-test-disabled`, `Delete enabled`, then the visited labels. Also, the rubric names `data-test-disabled="true"`, while the generated HTML/evidence only shows `aria-disabled`. So: PASS is probably correct, but evidence is slightly under-documented.

`conformance.context-menu-positioning` is the nuanced one. The bottom-right behavior itself appears correct: click at about `(1215,778)`, menu ends at `(1272,792)` in a `1280x800` viewport, so it shifted up/left and landed with an 8px inset. That satisfies the intent of flip-to-fit. But reducing the BR assertion to only `on_screen` is not a faithful enough reading of the tolerance language. The rubric does not require BR to keep its top-left anchored to the click, but it still requires an anchoring/fit relationship, not merely “somewhere on screen.”

I would mark the current evidence as:

- Keyboard nav: PASS, but add menu item/order/disabled-marker snapshot.
- Outside click: PASS, evidence sufficient.
- Positioning: current rects prove this run is okay, but the harness PASS predicate is underconstrained for BR and should record/compute flipped-edge tolerance, for example `viewport.w - menu.right <= 8`, `viewport.h - menu.bottom <= 8`, `menu.left < click.x`, `menu.top < click.y`, plus `on_screen`.
tokens used
59,292
No, I would not treat the PASS labels alone as fully proven for all three.

`focus.context-menu-outside-click-closes` looks sufficient. The record proves the menu was open, the click point was outside the menu rect, `data-presented` became `"false"`, dismiss reason was `"outside"`, and focus returned to `ctx-trigger-center`.

`focus.context-menu-keyboard-nav` is behaviorally convincing, and the six-key transcript is the right shape. The rubric asks for activeElement after `ArrowDown, ArrowDown, ArrowUp, Home, End, Escape`; this record has that plus the open state. I do not think it needs more per-key captures. The gap is that the JSON does not prove the disabled fixture/order independently. It should include a static menu item snapshot like `Open enabled`, `Rename enabled`, `Duplicate aria-disabled/data-test-disabled`, `Delete enabled`, then the visited labels. Also, the rubric names `data-test-disabled="true"`, while the generated HTML/evidence only shows `aria-disabled`. So: PASS is probably correct, but evidence is slightly under-documented.

`conformance.context-menu-positioning` is the nuanced one. The bottom-right behavior itself appears correct: click at about `(1215,778)`, menu ends at `(1272,792)` in a `1280x800` viewport, so it shifted up/left and landed with an 8px inset. That satisfies the intent of flip-to-fit. But reducing the BR assertion to only `on_screen` is not a faithful enough reading of the tolerance language. The rubric does not require BR to keep its top-left anchored to the click, but it still requires an anchoring/fit relationship, not merely “somewhere on screen.”

I would mark the current evidence as:

- Keyboard nav: PASS, but add menu item/order/disabled-marker snapshot.
- Outside click: PASS, evidence sufficient.
- Positioning: current rects prove this run is okay, but the harness PASS predicate is underconstrained for BR and should record/compute flipped-edge tolerance, for example `viewport.w - menu.right <= 8`, `viewport.h - menu.bottom <= 8`, `menu.left < click.x`, `menu.top < click.y`, plus `on_screen`.
