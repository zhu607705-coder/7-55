import departingStudentAUrl from "../../../assets/rpg/portraits/finale/runtime/departing_student_a.png";
import departingStudentBUrl from "../../../assets/rpg/portraits/finale/runtime/departing_student_b.png";

export interface ProloguePortraitPair {
  a: string;
  b: string;
  alt: string;
}

export const PROLOGUE_DEPARTING_STUDENT_PORTRAIT: ProloguePortraitPair = {
  a: departingStudentAUrl,
  b: departingStudentBUrl,
  alt: "准备离开教学楼的学生像素立绘"
};
