import Phaser from "phaser";
import stairwellUrl from "../../assets/rpg/interiors/finale/finale_stairwell.png";
import {
  CHASE_STAIR_SCENE_KEY, CHASE_STAIR_HANDOFF_KEY, CHASE_STAIR_SIZE, CHASE_STAIR_LANDINGS, CHASE_STAIR_GUARD_FOOT,
  CHASE_STAIR_GATES, CHASE_STAIR_EXIT, chaseStairBlockedRects, chaseStairInside,
  chaseStairPath, chaseStairDistance, type ChaseStairHandoff, type ChaseStairPoint
} from "../../modules/ChapterFourChaseStairwellModel";
import { CHAPTER_FOUR_FINAL_CHASE_RULES, chapterFourFinalChaseFootContact } from "../../modules/ChapterFourFinalChaseModel";
import type { ChapterFour755Intent } from "../../modules/ChapterFourTemporalMazeController";
import type { RpgBridge } from "./RpgBridge";
import { subscribeRpgSceneBridge } from "./RpgSceneBridgeSubscription";
import { configureRpgPlayerSprite, ensureRpgPlayerTextures, preloadRpgPlayerTextures, RpgPlayerAnimator } from "./RpgPlayerTextures";
import { FINALE_NPC_ANIMATIONS } from "./FinaleNpcTextures";
import { setRpgRuntimeDebugState, clearRpgRuntimeDebugState } from "./RpgRuntimeDebug";
const TEXTURE = "chapter-four-chase-stairwell-plate";
const GUARD_ANIMATIONS = ["guard_walk", "guard_walk_up", "guard_walk_down"] as const;
export const CHASE_STAIR_WARM_ASSET_URLS = [stairwellUrl, ...GUARD_ANIMATIONS.map(id=>FINALE_NPC_ANIMATIONS[id].url)] as const;

/** A source-sized walking segment, hosted in the same Phaser game and controller route. */
export class ChapterFourChaseStairwellScene extends Phaser.Scene {
  private bridge!: RpgBridge;
  private player!: Phaser.Physics.Arcade.Sprite;
  private guard!: Phaser.Physics.Arcade.Sprite;
  private animator!: RpgPlayerAnimator;
  private keys!: Record<"W"|"A"|"S"|"D",Phaser.Input.Keyboard.Key>;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;
  private virtual = {x:0,y:0};
  private elapsed = 0;
  private guardDelay = 0;
  private attempt = 0;
  private serial = 0;
  private pending: {id:string;type:ChapterFour755Intent["type"]}|null = null;
  private pendingTimer: Phaser.Time.TimerEvent|null = null;
  private guardTarget: ChaseStairPoint|null = null;
  private guardRepathMs = 0;
  private exitLabel!: Phaser.GameObjects.Text;
  constructor(){super(CHASE_STAIR_SCENE_KEY);}
  preload(): void {
    if(!this.textures.exists(TEXTURE))this.load.image(TEXTURE,stairwellUrl);
    preloadRpgPlayerTextures(this);
    for(const id of GUARD_ANIMATIONS){const a=FINALE_NPC_ANIMATIONS[id];if(!this.textures.exists(id))this.load.spritesheet(id,a.url,{frameWidth:a.frameWidth,frameHeight:a.frameHeight});}
  }
  create(): void {
    this.bridge=this.registry.get("rpgBridge") as RpgBridge;
    const chapter=this.bridge.getState().chapter4;
    this.attempt=chapter.chaseAttempt;this.elapsed=0;this.virtual={x:0,y:0};this.pending=null;this.guardTarget=null;this.guardRepathMs=0;
    this.add.image(0,0,TEXTURE).setOrigin(0).setDepth(-1000);
    this.physics.world.setBounds(0,0,CHASE_STAIR_SIZE.width,CHASE_STAIR_SIZE.height);
    ensureRpgPlayerTextures(this);
    for(const id of GUARD_ANIMATIONS){const a=FINALE_NPC_ANIMATIONS[id];if(!this.anims.exists(id))this.anims.create({key:id,frames:this.anims.generateFrameNumbers(id,{start:0,end:a.frameCount-1}),frameRate:a.fps,repeat:-1});}
    const landing=CHASE_STAIR_LANDINGS[chapter.chaseStairwellLanding]??CHASE_STAIR_LANDINGS[0];
    this.player=this.physics.add.sprite(landing.spawn.x,landing.spawn.y,"act1-player-up-0").setCollideWorldBounds(true);
    configureRpgPlayerSprite(this.player);this.placeFoot(this.player,landing.spawn);
    this.animator=new RpgPlayerAnimator(this.player,"up");
    this.guard=this.physics.add.sprite(landing.guard.x,landing.guard.y,"guard_walk_up",0).setOrigin(0.5,1).setScale(0.68).setCollideWorldBounds(true);
    const guardBody=this.guard.body as Phaser.Physics.Arcade.Body;
    guardBody.setSize(CHASE_STAIR_GUARD_FOOT.width/0.68,CHASE_STAIR_GUARD_FOOT.height/0.68).setOffset((96-CHASE_STAIR_GUARD_FOOT.width/0.68)/2,128-CHASE_STAIR_GUARD_FOOT.height/0.68);guardBody.pushable=false;
    const handoff=this.registry.get(CHASE_STAIR_HANDOFF_KEY) as ChaseStairHandoff|undefined;
    const sameHandoff=handoff?.attempt===this.attempt&&handoff.destination==="stairwell";
    const localDistance=Math.hypot(landing.spawn.x-landing.guard.x,landing.spawn.y-landing.guard.y);
    const lead=sameHandoff?Math.max(42,Math.min(2000,handoff.leadDistance)):localDistance+90;
    const guardSpawn=lead<localDistance
      ? {x:landing.spawn.x+(landing.guard.x-landing.spawn.x)*lead/localDistance,y:landing.spawn.y+(landing.guard.y-landing.spawn.y)*lead/localDistance}
      : landing.guard;
    this.placeFoot(this.guard,guardSpawn);
    this.guardDelay=Math.max(0,(lead-localDistance)/CHAPTER_FOUR_FINAL_CHASE_RULES.guardSpeed*1000);
    this.guard.setVisible(this.guardDelay===0).play("guard_walk_up");
    if(sameHandoff)this.registry.remove(CHASE_STAIR_HANDOFF_KEY);
    const obstacles=this.physics.add.staticGroup();
    for(const rect of chaseStairBlockedRects()){
      const zone=this.add.zone(rect.x+rect.width/2,rect.y+rect.height/2,rect.width,rect.height);
      this.physics.add.existing(zone,true);obstacles.add(zone);
    }
    this.physics.add.collider(this.player,obstacles);this.physics.add.collider(this.guard,obstacles);
    if(import.meta.env.DEV&&new URLSearchParams(location.search).get("debugChaseStairs")==="1"){
      const overlay=this.add.graphics().setDepth(999);
      for(const r of chaseStairBlockedRects())overlay.lineStyle(1,0xff5964,0.7).strokeRect(r.x,r.y,r.width,r.height);
    }
    this.exitLabel=this.add.text(844,98,"二楼走廊",{fontFamily:'"Fusion Pixel 12px Proportional SC", monospace',fontSize:"16px",color:"#fff2cb",backgroundColor:"#18212abb",padding:{x:8,y:5}}).setOrigin(0.5).setDepth(1000).setVisible(false);
    this.cursors=this.input.keyboard!.createCursorKeys();
    this.keys=this.input.keyboard!.addKeys("W,A,S,D") as typeof this.keys;
    // Camera-only headroom keeps the upper exit below the shared task bar; physics stays source-bounded.
    this.cameras.main.setBounds(0,-190,CHASE_STAIR_SIZE.width,CHASE_STAIR_SIZE.height+190).setZoom(1).startFollow(this.player,true,0.18,0.18).setDeadzone(150,80);
    this.cameras.main.centerOn(this.player.x,this.player.y);
    subscribeRpgSceneBridge(this.events,this.bridge,event=>{
      if(event.name==="rpg_direction_changed")this.virtual={x:Number(event.payload?.x)||0,y:Number(event.payload?.y)||0};
      if(event.name==="rpg_chapter4_755_intent_resolved"&&event.payload?.requestId===this.pending?.id){
        const pending=this.pending;this.pending=null;this.pendingTimer?.remove(false);this.pendingTimer=null;
        const result = event.payload?.result as { accepted?: boolean } | undefined;
        if(result?.accepted!==true){
          if(pending?.type==="leave_chase_stairwell")this.registry.remove(CHASE_STAIR_HANDOFF_KEY);
          this.bridge.emit("rpg_subtitle",{text:"沿平台继续上行，再进入上方楼梯口。",tone:"system",durationMs:2200});
        }
      }
    },()=>{
      this.virtual={x:0,y:0};this.pendingTimer?.remove(false);this.pending=null;
      clearRpgRuntimeDebugState();
    });
    this.bridge.emit("rpg_booted",{scene:"duan_yongping_temporal_maze",segment:"chase_stairwell"});
  }
  private foot(sprite:Phaser.Physics.Arcade.Sprite):ChaseStairPoint {const body=sprite.body as Phaser.Physics.Arcade.Body;return{x:body.center.x,y:body.center.y};}
  private placeFoot(sprite:Phaser.Physics.Arcade.Sprite,point:ChaseStairPoint):void {
    const body=sprite.body as Phaser.Physics.Arcade.Body;body.updateFromGameObject();
    sprite.setPosition(sprite.x+point.x-body.center.x,sprite.y+point.y-body.center.y);body.updateFromGameObject();
  }
  private request(intent:ChapterFour755Intent):void {
    if(this.pending)return;
    const id=`chase-stair-${this.attempt}-${this.time.now}-${++this.serial}`;
    this.pending={id,type:intent.type};
    this.pendingTimer=this.time.delayedCall(2000,()=>{this.pending=null;this.pendingTimer=null;});
    this.bridge.emit("rpg_chapter4_755_intent_requested",{requestId:id,intent});
  }
  update(_time:number,delta:number):void {
    if(!this.player||!this.guard)return;
    const chapter=this.bridge.getState().chapter4;
    if(chapter.phase!=="final_chase"||chapter.chaseStairwellStage!=="inside"||chapter.chaseAttempt!==this.attempt){this.player.setVelocity(0,0);this.guard.setVelocity(0,0);return;}
    this.elapsed+=Math.min(delta,100);
    const frozen=this.pending?.type==="leave_chase_stairwell"||this.pending?.type==="fail_chase";
    const motion=new Phaser.Math.Vector2(Number(this.cursors.right.isDown||this.keys.D.isDown)-Number(this.cursors.left.isDown||this.keys.A.isDown)+this.virtual.x,Number(this.cursors.down.isDown||this.keys.S.isDown)-Number(this.cursors.up.isDown||this.keys.W.isDown)+this.virtual.y);
    if(frozen)motion.set(0,0);else if(motion.lengthSq()>0)motion.normalize().scale(CHAPTER_FOUR_FINAL_CHASE_RULES.playerSpeed);
    this.player.setVelocity(motion.x,motion.y);this.animator.update(motion,this.time.now);
    const player=this.foot(this.player),guard=this.foot(this.guard);
    this.player.setDepth(500+player.y);this.guard.setDepth(502+guard.y);
    this.exitLabel.setVisible(chapter.chaseStairwellLanding===2&&Math.hypot(player.x-715,player.y-80)<175);
    const visible=this.elapsed>=this.guardDelay;
    this.guard.setVisible(visible);
    if(visible&&!frozen){
      this.guardRepathMs-=Math.min(delta,100);
      if(this.guardRepathMs<=0||!this.guardTarget||Math.hypot(this.guardTarget.x-guard.x,this.guardTarget.y-guard.y)<12){
        this.guardTarget=chaseStairPath(guard,player)[0]??null;this.guardRepathMs=100;
      }
      const vector=new Phaser.Math.Vector2(this.guardTarget?this.guardTarget.x-guard.x:0,this.guardTarget?this.guardTarget.y-guard.y:0);
      if(vector.lengthSq()>1)vector.normalize().scale(CHAPTER_FOUR_FINAL_CHASE_RULES.guardSpeed);else vector.set(0,0);
      this.guard.setVelocity(vector.x,vector.y);
      const animation=Math.abs(vector.y)>Math.abs(vector.x)?vector.y<0?"guard_walk_up":"guard_walk_down":"guard_walk";
      this.guard.setFlipX(animation==="guard_walk"&&vector.x<0).play(animation,true);
    }else this.guard.setVelocity(0,0);
    // Crossing the exit wins before contact on the same frame, as on the A2 threshold.
    if(!this.pending&&chapter.chaseStairwellLanding===2&&chaseStairInside(player,CHASE_STAIR_EXIT)){
      const lead=chaseStairDistance(guard,player)+Math.max(0,this.guardDelay-this.elapsed)*CHAPTER_FOUR_FINAL_CHASE_RULES.guardSpeed/1000;
      this.registry.set(CHASE_STAIR_HANDOFF_KEY,{attempt:this.attempt,destination:"A2",leadDistance:lead} satisfies ChaseStairHandoff);
      this.request({type:"leave_chase_stairwell",position:player,expectedAttempt:this.attempt});
    }else if(!this.pending&&visible&&chapterFourFinalChaseFootContact(guard,{x:(this.player.body as Phaser.Physics.Arcade.Body).x,y:(this.player.body as Phaser.Physics.Arcade.Body).y,width:this.player.body!.width,height:this.player.body!.height})){
      this.request({type:"fail_chase",expectedAttempt:this.attempt});
    }else if(!this.pending&&chapter.chaseStairwellLanding<2&&chaseStairInside(player,CHASE_STAIR_GATES[chapter.chaseStairwellLanding as 0 | 1])){
      this.request({type:"reach_chase_stairwell_landing",landing:(chapter.chaseStairwellLanding+1) as 1|2,position:player,expectedAttempt:this.attempt});
    }
    const body=this.player.body as Phaser.Physics.Arcade.Body;
    setRpgRuntimeDebugState({coordinateSystem:"Phaser world coordinates, origin at top-left, x right, y down",world:CHASE_STAIR_SIZE,scene:"duan_yongping_temporal_maze",checkpoint:this.bridge.getState().rpgCheckpoint,
      player:{x:player.x,y:player.y,facing:this.animator.facing,cardinalFacing:this.animator.cardinalFacing,collisionWidth:body.width,collisionHeight:body.height,footPoint:player},
      camera:{scrollX:this.cameras.main.scrollX,scrollY:this.cameras.main.scrollY,zoom:this.cameras.main.zoom,mode:"follow"},
      chaseStairwell:{active:true,landing:chapter.chaseStairwellLanding,attempt:this.attempt,guard,guardVisible:visible,guardTarget:this.guardTarget,remainingDistance:chaseStairDistance(player,{x:715,y:57}),gates:[...CHASE_STAIR_GATES],exit:CHASE_STAIR_EXIT,pending:this.pending?.type??null}
    });
  }
}
