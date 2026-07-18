/** 跨场景一次性导航意图（如“从主屏通知直接打开朋友聊天”） */
let openWechatFriendChat = false;
let requestGeneration = 0;
let scheduledClearGeneration: number | null = null;

export function requestFriendChat(): void {
  openWechatFriendChat = true;
  requestGeneration += 1;
}

export function consumeFriendChatIntent(): boolean {
  const value = openWechatFriendChat;
  if (value && scheduledClearGeneration !== requestGeneration) {
    const generation = requestGeneration;
    scheduledClearGeneration = generation;
    queueMicrotask(() => {
      if (requestGeneration === generation) {
        openWechatFriendChat = false;
      }
      if (scheduledClearGeneration === generation) {
        scheduledClearGeneration = null;
      }
    });
  }
  return value;
}
