/** Work-conserving bounded workers. Exclusive items are ordered drain barriers. */
export async function scheduleValidation(items, {jobs = 2, run, stopOnFailure = false}) {
  if (!Number.isInteger(jobs) || jobs < 1 || jobs > 4) throw Error('jobs must be 1..4');
  const results = new Map();
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
    let next = 0;
    await Promise.all(Array.from({length: Math.min(jobs, batch.length)}, async () => {
      while (!stopped && next < batch.length) await execute(batch[next++]);
    }));
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
