/** Work-conserving bounded workers. Exclusive items are ordered drain barriers. */
export async function scheduleValidation(items, {jobs = 2, run, stopOnFailure = false}) {
  if (!Number.isInteger(jobs) || jobs < 1 || jobs > 4) throw Error('jobs must be 1..4');
  const results = new Map(), ids = new Set(items.map(item => item.id));
  if (items.some(item => item.registration && item.registration.resources?.slots !== 1)) throw Error('Registered stages support only one worker slot');
  let stopped = false;
  async function execute(item) {
    if (stopped) return;
    try {
      const passed = await run(item);
      results.set(item.id, {status: passed === false ? 'failed' : 'pass'});
      if (passed === false && stopOnFailure) stopped = true;
    } catch (error) {
      results.set(item.id, {status: 'failed', error});
      stopped = true;
    }
  }
  async function readers(batch) {
    const pending = [...batch], active = new Set();
    while (pending.length || active.size) {
      if (stopped) {await Promise.all(active); return;}
      while (!stopped && active.size < jobs) {
        const next = pending.findIndex(item => (item.dependencies || []).every(id => !ids.has(id) || results.has(id)));
        if (next < 0) break;
        const [item] = pending.splice(next,1);
        // run() owns evidence-aware failure blocking. Readiness prevents a
        // dependent from observing an unfinished prerequisite as a failure.
        const promise = execute(item).finally(() => active.delete(promise)); active.add(promise);
      }
      if (active.size) await Promise.race(active);
      else if (pending.length) throw Error('Unresolved reader dependency or dependency crosses a later exclusive barrier');
    }
  }
  let pending = [];
  for (const item of items) {
    if (item.exclusive) {
      await readers(pending); pending = [];
      if (!stopped) await execute(item);
    } else pending.push(item);
  }
  await readers(pending);
  for (const item of items) if (!results.has(item.id)) results.set(item.id, {status: 'not-run'});
  const thrown = [...results.values()].find(row => row.error);
  if (thrown) throw thrown.error; // Already-started readers drained before rejection.
  return results;
}
