import type { SceneComponentProps } from "../../../components/ScenePlaceholder";
import { kit } from "../../../modules/GameKit";
import { PhotoEvidenceOverlay } from "../P13_PhoneHome/PhotoEvidenceOverlay";

export function PhotosScene({ state, router }: SceneComponentProps) {
  const puzzle = state.ui.libraryFinalsPuzzle;

  function changeBrightness(value: number) {
    kit.flags.setUi("brightness", value);
    if (value <= 20) {
      kit.libraryFinals.dimPhoto(value);
    }
  }

  function generateReport() {
    kit.libraryFinals.generateItemReport();
  }

  return (
    <PhotoEvidenceOverlay
      available={puzzle.backpackInspected}
      brightness={state.ui.brightness}
      dimmed={puzzle.photoDimmed}
      reportGenerated={puzzle.itemReportGenerated}
      onBrightnessChange={changeBrightness}
      onGenerate={generateReport}
      onClose={() => router.goTo("phone_home")}
    />
  );
}
