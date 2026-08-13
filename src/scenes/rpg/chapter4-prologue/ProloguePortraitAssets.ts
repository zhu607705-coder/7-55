import cleanerAUrl from "../../../assets/rpg/portraits/finale/runtime/cleaner_a.png";
import cleanerBUrl from "../../../assets/rpg/portraits/finale/runtime/cleaner_b.png";
import departingStudentAUrl from "../../../assets/rpg/portraits/finale/runtime/departing_student_a.png";
import departingStudentBUrl from "../../../assets/rpg/portraits/finale/runtime/departing_student_b.png";
import guardAUrl from "../../../assets/rpg/portraits/finale/runtime/guard_a.png";
import guardBUrl from "../../../assets/rpg/portraits/finale/runtime/guard_b.png";
import type { PrologueSubtitle } from "./PrologueTimeline";

export interface ProloguePortraitPair {
  a: string;
  b: string;
  alt: string;
}

const PORTRAITS = {
  cleaner: {
    a: cleanerAUrl,
    b: cleanerBUrl,
    alt: "保洁员手持拖把的像素立绘"
  },
  guard: {
    a: guardAUrl,
    b: guardBUrl,
    alt: "保安手持清楼名单和对讲机的像素立绘"
  },
  departing_student: {
    a: departingStudentAUrl,
    b: departingStudentBUrl,
    alt: "准备离开教学楼的学生像素立绘"
  }
} as const;

export function getProloguePortrait(subtitle: PrologueSubtitle | null): ProloguePortraitPair | null {
  if (subtitle?.id === "cleaner") return PORTRAITS.cleaner;
  if (subtitle?.id === "guard") return PORTRAITS.guard;
  return null;
}

export const PROLOGUE_DEPARTING_STUDENT_PORTRAIT = PORTRAITS.departing_student;
