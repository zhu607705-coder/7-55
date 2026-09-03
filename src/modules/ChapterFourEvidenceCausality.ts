import type { ChapterFourFactId, ChapterFourPhase } from "../core/types";
import content from "../data/chapter4-755.content.json";

export type ChapterFourEvidenceFamily = "time" | "paper_route" | "identity";

export interface ChapterFourEvidenceContract {
  id: string;
  family: ChapterFourEvidenceFamily;
  producerPhase: ChapterFourPhase;
  producerFacts: readonly ChapterFourFactId[];
  rawDetailIds: readonly string[];
  consumerPhases: readonly ChapterFourPhase[];
  consumedByFacts: readonly ChapterFourFactId[];
}

export type ChapterFourEvidencePhaseRole = "producer" | "consumer" | "either";

const CHAPTER_FOUR_PHASE_ORDER = Object.freeze(
  [...content.orderedPhases] as ChapterFourPhase[]
);
const CHAPTER_FOUR_PHASE_INDEX = new Map<ChapterFourPhase, number>(
  CHAPTER_FOUR_PHASE_ORDER.map((phase, index) => [phase, index])
);
const EVIDENCE_FAMILIES = new Set<ChapterFourEvidenceFamily>([
  "time",
  "paper_route",
  "identity"
]);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isUniqueNonEmptyStringArray(value: unknown): value is string[] {
  return Array.isArray(value)
    && value.length > 0
    && value.every((entry) => typeof entry === "string" && entry.trim().length > 0)
    && new Set(value).size === value.length;
}

function parseEvidenceContracts(value: unknown): ChapterFourEvidenceContract[] {
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error("Chapter 4 evidenceContracts must be a non-empty array");
  }

  const ids = new Set<string>();
  const rawDetailIds = new Set<string>();
  const producedFacts = new Set<string>();
  const consumedFacts = new Set<string>();
  const coveredPhases = new Set<ChapterFourPhase>();
  const parsed: ChapterFourEvidenceContract[] = [];

  for (const [index, candidate] of value.entries()) {
    if (!isRecord(candidate)) {
      throw new Error(`Chapter 4 evidence contract ${index} must be an object`);
    }
    const id = candidate.id;
    const family = candidate.family;
    const producerPhase = candidate.producerPhase;
    if (typeof id !== "string" || id.trim().length === 0 || ids.has(id)) {
      throw new Error(`Chapter 4 evidence contract ${index} has an invalid or duplicate id`);
    }
    if (typeof family !== "string"
      || !EVIDENCE_FAMILIES.has(family as ChapterFourEvidenceFamily)) {
      throw new Error(`Chapter 4 evidence contract ${id} has an invalid family`);
    }
    if (typeof producerPhase !== "string"
      || !CHAPTER_FOUR_PHASE_INDEX.has(producerPhase as ChapterFourPhase)
      || producerPhase === "complete") {
      throw new Error(`Chapter 4 evidence contract ${id} has an invalid producer phase`);
    }
    if (!isUniqueNonEmptyStringArray(candidate.producerFacts)
      || !isUniqueNonEmptyStringArray(candidate.rawDetailIds)
      || !isUniqueNonEmptyStringArray(candidate.consumerPhases)
      || !isUniqueNonEmptyStringArray(candidate.consumedByFacts)) {
      throw new Error(`Chapter 4 evidence contract ${id} has an invalid contract array`);
    }

    const producerIndex = CHAPTER_FOUR_PHASE_INDEX.get(producerPhase as ChapterFourPhase) ?? -1;
    const consumers = candidate.consumerPhases as ChapterFourPhase[];
    for (const consumerPhase of consumers) {
      const consumerIndex = CHAPTER_FOUR_PHASE_INDEX.get(consumerPhase);
      if (consumerIndex === undefined || consumerIndex <= producerIndex) {
        throw new Error(
          `Chapter 4 evidence contract ${id} consumer ${consumerPhase} must follow ${producerPhase}`
        );
      }
      coveredPhases.add(consumerPhase);
    }
    for (const detailId of candidate.rawDetailIds) {
      if (rawDetailIds.has(detailId)) {
        throw new Error(`Chapter 4 raw evidence detail ${detailId} has multiple owners`);
      }
      rawDetailIds.add(detailId);
    }
    for (const factId of candidate.producerFacts) producedFacts.add(factId);
    for (const factId of candidate.consumedByFacts) consumedFacts.add(factId);
    ids.add(id);
    coveredPhases.add(producerPhase as ChapterFourPhase);
    parsed.push(Object.freeze({
      id,
      family: family as ChapterFourEvidenceFamily,
      producerPhase: producerPhase as ChapterFourPhase,
      producerFacts: Object.freeze([...candidate.producerFacts]) as readonly ChapterFourFactId[],
      rawDetailIds: Object.freeze([...candidate.rawDetailIds]),
      consumerPhases: Object.freeze([...consumers]),
      consumedByFacts: Object.freeze([...candidate.consumedByFacts]) as readonly ChapterFourFactId[]
    }));
  }

  for (const factId of consumedFacts) {
    if (!producedFacts.has(factId)) {
      throw new Error(`Chapter 4 consumed evidence fact ${factId} has no producer contract`);
    }
  }
  for (const phase of CHAPTER_FOUR_PHASE_ORDER) {
    if (!coveredPhases.has(phase)) {
      throw new Error(`Chapter 4 phase ${phase} does not produce or consume durable evidence`);
    }
  }

  return parsed;
}

export const CHAPTER_FOUR_EVIDENCE_CONTRACTS = Object.freeze(
  parseEvidenceContracts((content as { evidenceContracts?: unknown }).evidenceContracts)
);

const CHAPTER_FOUR_EVIDENCE_BY_ID = new Map(
  CHAPTER_FOUR_EVIDENCE_CONTRACTS.map((contract) => [contract.id, contract])
);

export const CHAPTER_FOUR_EVIDENCE_VALIDATION = Object.freeze({
  contractCount: CHAPTER_FOUR_EVIDENCE_CONTRACTS.length,
  rawDetailCount: CHAPTER_FOUR_EVIDENCE_CONTRACTS.reduce(
    (count, contract) => count + contract.rawDetailIds.length,
    0
  ),
  multiPhaseReuseCount: CHAPTER_FOUR_EVIDENCE_CONTRACTS.filter((contract) => (
    contract.consumerPhases.some((phase) => (
      (CHAPTER_FOUR_PHASE_INDEX.get(phase) ?? 0)
        - (CHAPTER_FOUR_PHASE_INDEX.get(contract.producerPhase) ?? 0) >= 2
    ))
  )).length
});

export function getChapterFourEvidenceContract(
  id: string
): ChapterFourEvidenceContract | null {
  return CHAPTER_FOUR_EVIDENCE_BY_ID.get(id) ?? null;
}

export function selectChapterFourEvidenceContractsForPhase(
  phase: ChapterFourPhase,
  role: ChapterFourEvidencePhaseRole = "either"
): readonly ChapterFourEvidenceContract[] {
  return CHAPTER_FOUR_EVIDENCE_CONTRACTS.filter((contract) => {
    const produces = contract.producerPhase === phase;
    const consumes = contract.consumerPhases.includes(phase);
    if (role === "producer") return produces;
    if (role === "consumer") return consumes;
    return produces || consumes;
  });
}

export function getMissingChapterFourEvidenceProducerFacts(
  contractId: string,
  factIds: readonly ChapterFourFactId[]
): readonly ChapterFourFactId[] {
  const contract = getChapterFourEvidenceContract(contractId);
  if (!contract) return Object.freeze([]);
  const available = new Set(factIds);
  return Object.freeze(contract.producerFacts.filter((factId) => !available.has(factId)));
}

export function isChapterFourEvidenceReady(
  contractId: string,
  factIds: readonly ChapterFourFactId[]
): boolean {
  return getMissingChapterFourEvidenceProducerFacts(contractId, factIds).length === 0;
}
