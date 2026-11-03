import type { FastifyInstance, FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";
import { gameSaveHeadSchema, gameSaveWriteSchema, gameSaveRestoreSchema, saveShaSchema, SAVE_LIMITS, type User } from "@755/contracts";
import { CommunityError, type GameSaveStore } from "@755/database";

interface Access {
  protect(request: FastifyRequest, reply: FastifyReply): Promise<void>;
  member(request: FastifyRequest): Promise<User>;
  writeMember(request: FastifyRequest, reply: FastifyReply): Promise<User>;
}
export function registerGameSaves(app: FastifyInstance, store: GameSaveStore, access: Access) {
  const base="/api/v1/me/game-save", owners=new WeakMap<FastifyRequest,User>();
  const read=async (request: FastifyRequest) => {
    const user=await access.member(request);
    if (request.headers["x-755-member"] && request.headers["x-755-member"]!==user.id)
      throw new CommunityError(409,"CONFLICT","账号已切换，请重新选择本人存档。");
    owners.set(request,user);
  };
  const write=async (request: FastifyRequest,reply: FastifyReply) => {
    await access.protect(request,reply);
    await read(request);
    await access.writeMember(request,reply);
  };
  function parse<T>(schema:z.ZodType<T>, value:unknown):T {
    const result=schema.safeParse(value);
    if (!result.success) throw new CommunityError(400,"INVALID_REQUEST","存档请求格式不正确。");
    return result.data;
  }
  const owner=(request:FastifyRequest)=>owners.get(request)!.id;
  if (!app.hasContentTypeParser("application/octet-stream"))
    app.addContentTypeParser("application/octet-stream",{parseAs:"buffer"},(_request,body,done)=>done(null,body));
  app.get(base,{onRequest:read},async request=>gameSaveHeadSchema.parse(await store.head(owner(request))));
  app.get(base+"/snapshots/:id",{onRequest:read},async request=>{
    const {id}=parse(z.object({id:z.uuid()}),request.params);
    return store.snapshot(owner(request),id);
  });
  app.get(base+"/assets/:sha",{onRequest:read,exposeHeadRoute:false},async (request,reply)=>{
    const {sha}=parse(z.object({sha:saveShaSchema}),request.params);
    reply.type("application/octet-stream");
    reply.header("Content-Disposition","attachment");
    return store.asset(owner(request),sha);
  });
  app.head(base+"/assets/:sha",{onRequest:read},async (request,reply)=>{
    const {sha}=parse(z.object({sha:saveShaSchema}),request.params);
    return reply.code(await store.assetExists(owner(request),sha) ? 200 : 404).send();
  });
  app.put(base+"/assets/:sha",{onRequest:write,bodyLimit:SAVE_LIMITS.image},async request=>{
    const {sha}=parse(z.object({sha:saveShaSchema}),request.params);
    if (!Buffer.isBuffer(request.body)) throw new CommunityError(400,"INVALID_REQUEST","照片需要二进制内容。");
    return store.putAsset(owner(request),sha,request.body);
  });
  for (const [method,url,kind] of [["PUT",base,"save"],["POST",base+"/restart","restart"],["POST",base+"/restore","restore"]] as const) {
    app.route({method,url,onRequest:write,bodyLimit:kind==="restore" ? 4096 : 64*1024**2,handler:async request=>{
      const input=kind==="restore" ? parse(gameSaveRestoreSchema,request.body) : parse(gameSaveWriteSchema,request.body);
      return gameSaveHeadSchema.parse(await store.write(owner(request),input,kind));
    }});
  }
}
