# Explicit migration scope (2026-09-17)

The owner's new request explicitly authorizes a Godot conversion. Within this
standalone `godot-port/` experiment, that request supersedes the older root ban
on new Godot work. It also authorizes the associated exporter, contract tests,
CI workflow and migration ADR. The root web-runtime policy otherwise remains
unchanged. Do not import/mount this project in the current React application.

This directory is an executable spatial-parity slice, not a completed game port.
It must not write progression, open production saves or claim chapter parity.
Use Godot's CharacterBody2D, collision shapes, Camera2D and native Y sorting;
do not implement another physics solver or general-purpose scene engine.
Source-pixel map geometry and player assets are exported from existing TypeScript
constants. Never hand-maintain a second authored coordinate table here.
Generated assets and .godot caches must not be committed.

Before promoting this experiment: validate native engine import, collision and
visual parity, input/focus behavior, then move domain rules through replay-based
parity gates. Record untested functionality explicitly. Keep production web CI.
