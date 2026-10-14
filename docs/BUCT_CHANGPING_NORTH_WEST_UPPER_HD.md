# Left northern Changping terrain

Default-enabled ROI [118,167,256,256], core [130,179,232,232]. Native generator output 1254×1254; runtime registration is 1024×1024, four texels per source pixel. Uniform registered genuine detail density is 4.8857. No geometry or road is transformed.

New accepted HD terrain: 45,556 source cells (42,600 terrain-first plus 2,956 retired by one accepted independent body). All 8,268 remaining original-body core cells are excluded. Terrain coverage is now 310,684 / 1,573,200 = 19.75% of the Changping canvas. Campus inclusion is visual source review, not a surveyed boundary. Haidian/Chaoyang remain zero accepted HD terrain in this package.

Seven original left/northern building envelopes retain the original bodies; dorm_nw_02 is now accepted independent RGBA. The narrow generated Hill remnant inside that original mask does not count toward terrain and must be cleared if the original Hill is later retired.

Minimal startup/physical/lifecycle smoke passed. The original 150 physical records, 83 paving polygons, visitor position/scale and source data are exact. Real X11/OpenGL produced a 2464×1024 contiguous northern view and a 950×1656 full-campus view. The new seam has normal visual acceptance only; prior V4 29-check actual ownership proof is reused without repeating its matrix. No manual walking or hardware VRAM/performance claim is made.

The new logical texture allocation is 6,204,069 bytes; six region layers total 52,283,306 bytes. Independent building allocation remains separate: dorm_nw_02 adds 9,967,612 bytes. No cap is raised. Original logical roads and collisions are independent of display residency.

Full scope and raw evidence hashes: BUCT_CHANGPING_NORTH_WEST_UPPER_HD_VALIDATION.json. This depends on PR138 exact source commit 72fcafd285dd388eed2735be71b60fa23f428548; target is godot-version, never main. No merge is performed.
