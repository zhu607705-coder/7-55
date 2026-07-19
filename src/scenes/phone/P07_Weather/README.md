# P07 Weather

- Scene ID: `weather`
- Entry: weather widget
- Reads: `actOne.exerciseStarted`, `actOne.weatherWaterTaken`
- Writes: `items.weatherWater`, `actOne.weatherWaterTaken`
- Events: `get_item`
- Contract: 课外锻炼开始后即可独立收集天气水滴，不依赖主页三角形的取得顺序。
- Assets: rainy widget, collectible drop
