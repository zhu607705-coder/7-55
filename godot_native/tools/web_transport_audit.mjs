import {createHash} from 'node:crypto';

// Independent HTTP evidence overlaps ordinary browser input, not its authority.
// Every manifest entry is still fetched and hashed in full; concurrency is bounded
// and a browser failure cancels/drains all outstanding responses before exit.
export function startTransportAudit({resources, locate, check, shaFile, exists, onAsset,
  fetchImpl = fetch, concurrency = 2, timeoutMs = 60000}) {
  if (!Number.isInteger(concurrency) || concurrency < 1 || concurrency > 4 ||
      !Number.isFinite(timeoutMs) || timeoutMs <= 0) throw Error('Invalid transport audit limits');
  const controller = new AbortController();
  const evidence = {startedAt: Date.now(), concurrency, expected: resources.length, completed: 0};
  let next = 0, failure;
  async function worker() {
    while (!controller.signal.aborted) {
      const index = next++;
      if (index >= resources.length) return;
      const resource = resources[index];
      let relativePath = resource.url, local;
      const timer = new AbortController();
      const timeout = setTimeout(() => timer.abort(Error(`HTTP transport deadline: ${relativePath}`)), timeoutMs);
      const signal = AbortSignal.any([controller.signal, timer.signal]);
      try {
        ({relativePath, local} = locate(resource.url));
        const response = await fetchImpl(resource.url, {cache: 'no-cache', signal});
        check(response.status === 200, `transport asset independently fetched in full: ${relativePath}`);
        const digest = createHash('sha256'); let bytes = 0;
        for await (const chunk of response.body) { signal.throwIfAborted(); digest.update(chunk); bytes += chunk.length; }
        const sha256 = digest.digest('hex');
        check(bytes === resource.bytes && sha256 === resource.sha256,
          `independent HTTP transport bytes match the actual manifest: ${relativePath}`,
          {bytes, sha256, expectedBytes: resource.bytes, expectedSha256: resource.sha256});
        if (local) {
          check(exists(local), `export artifact exists: ${relativePath}`);
          check(await shaFile(local) === sha256, `HTTP bytes match actual Godot export: ${relativePath}`);
        }
        signal.throwIfAborted();
        onAsset({url: resource.url, relativePath, role: resource.role, resource: resource.resource, bytes, sha256, local}, index);
        evidence.completed++;
      } catch (error) {
        failure ||= error;
        controller.abort(error);
      } finally { clearTimeout(timeout); }
    }
  }
  // Attach rejection handling immediately: browser input may run for minutes.
  const completion = Promise.all(Array.from({length: concurrency}, worker)).then(() => {
    evidence.finishedAt = Date.now(); evidence.elapsedMs = evidence.finishedAt - evidence.startedAt;
    if (failure || controller.signal.aborted) return {error: failure || controller.signal.reason};
    if (evidence.completed !== resources.length) return {error: Error('Incomplete transport audit')};
    return {evidence};
  });
  return {evidence, completion, cancel(reason = Error('Browser acceptance ended before transport audit')) {controller.abort(reason);}};
}
