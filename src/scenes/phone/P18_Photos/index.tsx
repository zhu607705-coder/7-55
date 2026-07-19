import { useEffect, useRef } from "react";
import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { kit } from "../../../modules/GameKit";
import { PhotoEvidenceOverlay } from "../P13_PhoneHome/PhotoEvidenceOverlay";

export function PhotosScene({ state, router }: SceneComponentProps) {
  const puzzle = state.ui.libraryFinalsPuzzle;
  const brightnessAtCaptureRef = useRef<number | null>(
    puzzle.photoCaptured && !puzzle.photoDimmed ? state.ui.brightness : null
  );
  const previousBrightnessRef = useRef(state.ui.brightness);

  useEffect(() => {
    const previousBrightness = previousBrightnessRef.current;
    previousBrightnessRef.current = state.ui.brightness;
    if (!puzzle.photoCaptured || puzzle.photoDimmed) return;
    if (brightnessAtCaptureRef.current === null) {
      brightnessAtCaptureRef.current = state.ui.brightness;
      return;
    }
    const adjustedAfterCapture = state.ui.brightness !== previousBrightness
      && state.ui.brightness !== brightnessAtCaptureRef.current;
    if (adjustedAfterCapture && state.ui.brightness <= 20) {
      kit.libraryFinals.dimPhoto(state.ui.brightness);
    }
  }, [puzzle.photoCaptured, puzzle.photoDimmed, state.ui.brightness]);

  function capturePhoto() {
    const wasCaptured = puzzle.photoCaptured;
    const brightnessAtCapture = state.ui.brightness;
    const captured = kit.libraryFinals.capturePhoto();
    if (captured && !wasCaptured) {
      brightnessAtCaptureRef.current = brightnessAtCapture;
      previousBrightnessRef.current = brightnessAtCapture;
    }
    return captured;
  }

  function generateReport() {
    kit.libraryFinals.generateItemReport();
  }

  return (
    <PhotoEvidenceOverlay
      available={puzzle.backpackInspected}
      brightness={state.ui.brightness}
      captured={puzzle.photoCaptured}
      dimmed={puzzle.photoDimmed}
      reportGenerated={puzzle.itemReportGenerated}
      onCapture={capturePhoto}
      onGenerate={generateReport}
      onClose={() => router.goTo("phone_home")}
    />
  );
}
