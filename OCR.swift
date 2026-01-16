import Foundation
import Vision
import ImageIO

final class LabelOCR {
    private let queue = DispatchQueue(label: "LabelOCR.queue", qos: .userInitiated)

    func recognizeLines(from cgImage: CGImage, orientation: CGImagePropertyOrientation, completion: @escaping ([String]) -> Void) {
        let request = VNRecognizeTextRequest { req, err in
            if err != nil {
                completion([])
                return
            }
            let observations = (req.results as? [VNRecognizedTextObservation]) ?? []
            let lines: [String] = observations.compactMap { $0.topCandidates(1).first?.string }
            completion(lines)
        }

        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        queue.async {
            do {
                try handler.perform([request])
            } catch {
                completion([])
            }
        }
    }
}
