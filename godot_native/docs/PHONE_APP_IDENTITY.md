# Native Weather and Tiyi identity

The native Weather page now uses original Godot-drawn cloud, rain, water and wind shapes with a cool sky palette. The Tiyi page keeps the bundled sports artwork and the exact47 clue geometry; its native controls use readable blue/green states instead of the generic warm-paper palette. No new third-party icon or brand artwork was imported.

The changes preserve original Chinese labels, action IDs, enabled states, callback payloads and control rectangles. The shared Fusion font remains unchanged. Tiyi white-label contrast is at least4.7569:1 across normal, hover, pressed, hover-pressed and disabled fills before screen effects. The source-timed entry and anomaly session owns loading/crash behavior separately.

## Validation

`test_phone_app_identity.gd` checks15 state fixtures against the previously independently compared page contract: exact labels, action payloads, button geometry/disabled states, no builder-side story writes, canonical page width, weather condition and Tiyi contrast. It passes160 assertions. The contract fixture is presentation-independent and does not bypass the production Tiyi entry session.

Cloud Linux graphical review covered16 current Weather/Tiyi images at390×844,430×860 and1280×900. Phone frame rectangles remained354×708,394×788 and430×860 respectively. The actual player run also used the new Tiyi page to collect7. These checks do not claim a physical mobile-device test or complete app parity.

## References and boundaries

- Weather source: `src/scenes/phone/P07_Weather/index.tsx` and `src/styles/scenes/ch2-movement.css`
- Tiyi source: `src/scenes/phone/P06_Tiyi/index.tsx`, `src/styles/scenes/p06-tiyi.css` and `src/styles/library-v2-phone.css`
- Familiar weather categories were visually compared with [Apple's weather-icon guide](https://support.apple.com/zh-cn/guide/iphone/iph4305794fb/ios); no Apple paths/assets were copied
- The existing sports identity was checked against the [official Tiyi listing](https://apps.apple.com/cn/app/%E6%B5%99%E5%A4%A7%E4%BD%93%E8%89%BA/id1121503200); its copyrighted assets were not newly imported

WeChat and Zjuding retain their authored chat/workbench identities. Broader spacing, glyph and effect comparisons remain in the acceptance backlog.
