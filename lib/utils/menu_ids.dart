// REAL menu ids — modules the backend has granted in tbl_MobileAppMenu, live
// against production data. Nothing here is a demo or a placeholder; the demo
// tiles (ARK Solutions) exist only in the Dicor app, not here.
//
// A module only needs an entry below when it has no PNG in assets/iconsnew
// yet: [menuFallbackIcons] is what the home / quick-links tile falls back to.

import 'package:flutter/material.dart';

/// Production — Operator ("My Jobs"): the INTERIA shop-floor flow — produce,
/// QC, rework, loader hand-off. Backed by the live `interia/*` endpoints.
const int kMenuMyJobs = 9404;

/// Order Production Tracking: read-only supervisor view of who did what on
/// every order. Backed by the live `interia/track/*` endpoints.
const int kMenuOrderTracking = 9405;

/// Tile icons for real modules that have no artwork yet.
const Map<int, IconData> menuFallbackIcons = {
  kMenuMyJobs: Icons.precision_manufacturing_outlined,
  kMenuOrderTracking: Icons.insights_outlined,
};
