import { createHash, randomUUID } from "node:crypto";
import type pg from "pg";
import { SAVE_LIMITS, type GameSaveBundle, type GameSaveWrite, type GameSaveRestore, type GameSaveHead } from "@755/contracts";
import { CommunityError } from "./community.js";

const hash = (value: string | Buffer) => createHash("sha256").update(value).digest("hex");
const invalid = (message = "存档内容不符合要求。") => new CommunityError(400,"INVALID_REQUEST",message);
const conflict = (message: string) => new CommunityError(409,"CONFLICT",message);
const missing = () => new CommunityError(404,"NOT_FOUND","找不到这份本人存档。");
export function validateSaveBundle(bundle: GameSaveBundle) {
  if (Buffer.byteLength(bundle.stateText) > SAVE_LIMITS.state) throw invalid("核心存档超过大小限制。");
  for (const text of Object.values(bundle.stores)) if (Buffer.byteLength(text) > SAVE_LIMITS.document) throw invalid("编辑文档超过大小限制。");
  let envelope, posts, overrides;
  try { envelope = JSON.parse(bundle.stateText); posts = JSON.parse(bundle.stores.posts); overrides = JSON.parse(bundle.stores.questPostOverrides); }
  catch { throw invalid("存档或编辑文档不是有效 JSON。"); }
  if (!envelope || envelope.format !== "7-55-godot-native" || envelope.version !== 1 ||
      !Number.isInteger(envelope.sourceVersion) || envelope.sourceVersion < 1 || envelope.sourceVersion > 36 ||
      !envelope.state || typeof envelope.state !== "object" || Array.isArray(envelope.state) ||
      !Array.isArray(posts) || !overrides || typeof overrides !== "object" || Array.isArray(overrides)) throw invalid("存档版本或封装不兼容。");
  const journal = envelope.state.qizhenLake?.journal ?? {};
  const photos = [journal.mainPhoto, ...Object.values(journal.optionalPhotos ?? {}), journal.pendingDraft?.photo];
  const required = new Set<string>();
  for (const photo of photos) {
    if (!photo || typeof photo !== "object" || !("nativeImagePath" in photo)) continue;
    if (!/^[a-f0-9]{64}$/.test(String(photo.nativeImageSha256))) throw invalid("存档照片缺少有效指纹。");
    required.add(photo.nativeImageSha256);
  }
  if (new Set(bundle.assets).size !== bundle.assets.length || required.size !== bundle.assets.length || bundle.assets.some(sha => !required.has(sha))) throw invalid("照片清单与存档不一致。");
  if (bundle.summary.chapter !== envelope.state.native?.chapter) throw invalid("章节摘要与存档不一致。");
  return { sourceVersion: envelope.sourceVersion as number, digest: hash(JSON.stringify(bundle)), bytes: Buffer.byteLength(JSON.stringify(bundle)) };
}
export function validateSaveImage(sha: string, data: Buffer) {
  if (data.length < 33 || data.length > SAVE_LIMITS.image || hash(data) !== sha ||
      !data.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])) ||
      data.readUInt32BE(8) !== 13 || data.toString("ascii",12,16) !== "IHDR") throw invalid("照片内容或指纹无效。");
  const width=data.readUInt32BE(16),height=data.readUInt32BE(20);
  if (width<320 || width>3840 || height<180 || height>2160) throw invalid("照片尺寸不符合要求。");
}

export function createGameSaveStore(pool: pg.Pool) {
  async function transaction<T>(member: string, run: (client: pg.PoolClient, head: any) => Promise<T>) {
    const client=await pool.connect();
    try {
      await client.query("BEGIN");
      await client.query("INSERT INTO game_save_heads(member_id) VALUES($1) ON CONFLICT DO NOTHING",[member]);
      const {rows}=await client.query("SELECT * FROM game_save_heads WHERE member_id=$1 FOR UPDATE",[member]);
      const value=await run(client,rows[0]);
      await client.query("COMMIT"); return value;
    } catch(error) { await client.query("ROLLBACK"); throw error; } finally { client.release(); }
  }
  async function readHead(client: pg.Pool | pg.PoolClient, member: string): Promise<GameSaveHead> {
    const {rows}=await client.query(`SELECT h.revision,s.id,s.digest,s.created_at,s.source_version,s.bundle->'summary' AS summary,
      h.current_id,h.previous_id,h.before_restart_id FROM game_save_heads h LEFT JOIN game_save_snapshots s
      ON s.member_id=h.member_id AND s.id IN(h.current_id,h.previous_id,h.before_restart_id) WHERE h.member_id=$1`,[member]);
    const row=rows[0];
    const summary=(id: string | null) => {
      const snapshot=rows.find(r=>r.id===id && id!==null);
      return snapshot ? {id:snapshot.id,digest:snapshot.digest,savedAt:new Date(snapshot.created_at).toISOString(),sourceVersion:snapshot.source_version,...snapshot.summary} : null;
    };
    return {memberId:member,revision:Number(row?.revision??0),current:summary(row?.current_id),previous:summary(row?.previous_id),beforeRestart:summary(row?.before_restart_id)};
  }
  async function quota(client: pg.PoolClient, member: string) {
    const {rows}=await client.query(`SELECT COALESCE((SELECT sum(bytes) FROM game_save_snapshots WHERE member_id=$1),0)+
      COALESCE((SELECT sum(octet_length(data)) FROM game_save_assets WHERE member_id=$1),0) AS bytes`,[member]);
    if (Number(rows[0].bytes)>SAVE_LIMITS.quota) throw conflict("账号存档空间不足，原云存档未改变。");
  }
  async function collect(client: pg.PoolClient, member: string) {
    await client.query(`DELETE FROM game_save_snapshots s USING game_save_heads h WHERE s.member_id=$1 AND h.member_id=s.member_id
      AND NOT(s.id=ANY(array_remove(ARRAY[h.current_id,h.previous_id,h.before_restart_id],NULL)))`,[member]);
    await client.query(`DELETE FROM game_save_assets a WHERE a.member_id=$1 AND a.created_at<now()-interval '24 hours'
      AND NOT EXISTS(SELECT 1 FROM game_save_snapshots s WHERE s.member_id=a.member_id AND s.bundle->'assets' ? a.sha)`,[member]);
    await client.query("DELETE FROM game_save_operations WHERE member_id=$1 AND created_at<now()-interval '24 hours'",[member]);
  }
  return {
    head: (member: string) => readHead(pool,member),
    async snapshot(member: string,id: string) {
      const {rows}=await pool.query(`SELECT bundle,digest FROM game_save_snapshots s JOIN game_save_heads h USING(member_id)
        WHERE s.member_id=$1 AND s.id=$2 AND s.id IN(h.current_id,h.previous_id,h.before_restart_id)`,[member,id]);
      if (!rows[0]) throw missing(); return rows[0] as {bundle:GameSaveBundle;digest:string};
    },
    async assetExists(member: string,sha: string) {
      const result=await pool.query("SELECT 1 FROM game_save_assets WHERE member_id=$1 AND sha=$2",[member,sha]);
      return result.rowCount===1;
    },
    async asset(member: string,sha: string) {
      const {rows}=await pool.query("SELECT data FROM game_save_assets WHERE member_id=$1 AND sha=$2",[member,sha]);
      if (!rows[0]) throw missing(); return rows[0].data as Buffer;
    },
    async putAsset(member: string,sha: string,data: Buffer) {
      validateSaveImage(sha,data);
      await transaction(member,async client=>{
        await collect(client,member);
        await client.query("INSERT INTO game_save_assets(member_id,sha,data) VALUES($1,$2,$3) ON CONFLICT DO NOTHING",[member,sha,data]);
        await quota(client,member);
      });
      return {ok:true};
    },
    async write(member: string,input: GameSaveWrite | GameSaveRestore, kind: "save" | "restart" | "restore" = "save") {
      if (input.expectedMemberId!==member) throw conflict("账号已切换，旧账号进度未上传。");
      const requestDigest=hash(JSON.stringify({kind,input}));
      return transaction(member,async (client,head)=>{
        const prior=await client.query("SELECT request_digest,result FROM game_save_operations WHERE member_id=$1 AND operation_id=$2",[member,input.operationId]);
        if (prior.rows[0]) {
          if (prior.rows[0].request_digest!==requestDigest) throw conflict("同一保存操作不能修改内容后重试。");
          if (Number(head.revision)!==prior.rows[0].result.revision) throw conflict("这次保存曾经成功，但云端已有后续进度，请比较后选择。");
          return prior.rows[0].result as GameSaveHead;
        }
        if (Number(head.revision)!==input.expectedRevision) throw conflict("其他页面或设备更新了进度，请比较两份存档后选择。");
        let id: string;
        if (kind==="restore") {
          id=(input as GameSaveRestore).snapshotId;
          if (![head.current_id,head.previous_id,head.before_restart_id].includes(id)) throw missing();
        } else {
          const bundle=(input as GameSaveWrite).bundle;
          const checked=validateSaveBundle(bundle);
          const assets=await client.query("SELECT sha,octet_length(data) AS bytes FROM game_save_assets WHERE member_id=$1 AND sha=ANY($2::text[])",[member,bundle.assets]);
          if (assets.rowCount!==bundle.assets.length || assets.rows.reduce((sum,r)=>sum+r.bytes,0)>SAVE_LIMITS.images) throw invalid("必需照片未上传完整或超过大小限制。");
          // Identical manual saves acknowledge the actual current snapshot, without backup churn.
          const same=await client.query("SELECT id FROM game_save_snapshots WHERE id=$1 AND member_id=$2 AND digest=$3",[head.current_id,member,checked.digest]);
          id=kind==="save" && same.rows[0] ? same.rows[0].id : randomUUID();
          if (!same.rows[0] || kind!=="save") await client.query(`INSERT INTO game_save_snapshots(id,member_id,bundle,digest,source_version,bytes)
            VALUES($1,$2,$3,$4,$5,$6)`,[id,member,bundle,checked.digest,checked.sourceVersion,checked.bytes]);
        }
        if (id!==head.current_id || kind!=="save") await client.query(`UPDATE game_save_heads SET revision=revision+1,previous_id=current_id,
          before_restart_id=CASE WHEN $3='restart' THEN COALESCE(current_id,before_restart_id) ELSE before_restart_id END,current_id=$2 WHERE member_id=$1`,[member,id,kind]);
        await collect(client,member); await quota(client,member);
        const result=await readHead(client,member);
        await client.query("INSERT INTO game_save_operations(member_id,operation_id,request_digest,result) VALUES($1,$2,$3,$4)",[member,input.operationId,requestDigest,result]);
        return result;
      });
    },
  };
}
export type GameSaveStore = ReturnType<typeof createGameSaveStore>;
