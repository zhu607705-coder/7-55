import {
  CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE,
  closureProofMatchesReference,
  type ChapterFourClosureSessionProof,
  type ChapterFourClosureSessionVerifier
} from "./ChapterFourClosureContract";

interface ClosureSessionRecord {
  completionEventId: string | null;
  completed: boolean;
  consumed: boolean;
}

let closureSessionSerial = 0;

/** Runtime-only registry for one official lamp playback and one completion write. */
export class ChapterFourClosureSessionRegistry implements ChapterFourClosureSessionVerifier {
  readonly reference = CHAPTER_FOUR_APPROVED_CLOSURE_REFERENCE;

  private readonly sessions = new Map<string, ClosureSessionRecord>();

  beginSession(): string {
    closureSessionSerial += 1;
    const sessionId = `chapter4-star-lamp-${Date.now()}-${closureSessionSerial}`;
    this.sessions.set(sessionId, {
      completionEventId: null,
      completed: false,
      consumed: false
    });
    return sessionId;
  }

  completeSession(sessionId: string): ChapterFourClosureSessionProof | null {
    const session = this.sessions.get(sessionId);
    if (!session || session.completed || session.consumed) return null;
    const completionEventId = `${sessionId}:sequence-complete`;
    session.completed = true;
    session.completionEventId = completionEventId;
    return Object.freeze({
      assetId: this.reference.assetId,
      sequenceId: this.reference.sequenceId,
      consumerModule: this.reference.consumerModule,
      sessionId,
      completionEventId
    });
  }

  verifyCompletedSession(proof: ChapterFourClosureSessionProof): boolean {
    if (!closureProofMatchesReference(proof, this.reference)) return false;
    const session = this.sessions.get(proof.sessionId);
    if (!session
      || !session.completed
      || session.consumed
      || session.completionEventId !== proof.completionEventId) return false;
    session.consumed = true;
    return true;
  }

  cancelSession(sessionId: string): void {
    this.sessions.delete(sessionId);
  }
}
