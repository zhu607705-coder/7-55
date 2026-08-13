/** 跨场景一次性导航意图（如“从主屏通知直接打开朋友聊天”） */
let openWechatFriendChat = false;
let requestGeneration = 0;
let scheduledClearGeneration: number | null = null;
let openCc98ThreadId: string | null = null;
let cc98RequestGeneration = 0;
let scheduledCc98ClearGeneration: number | null = null;

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

export function requestCc98Thread(threadId: string): void {
  openCc98ThreadId = threadId;
  cc98RequestGeneration += 1;
}

export function consumeCc98ThreadIntent(): string | null {
  const value = openCc98ThreadId;
  if (value && scheduledCc98ClearGeneration !== cc98RequestGeneration) {
    const generation = cc98RequestGeneration;
    scheduledCc98ClearGeneration = generation;
    queueMicrotask(() => {
      if (cc98RequestGeneration === generation) {
        openCc98ThreadId = null;
      }
      if (scheduledCc98ClearGeneration === generation) {
        scheduledCc98ClearGeneration = null;
      }
    });
  }
  return value;
}
