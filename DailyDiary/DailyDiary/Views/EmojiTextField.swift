import SwiftUI
import UIKit

struct EmojiTextField: UIViewRepresentable {
    @Binding var selectedEmoji: String
    var onSelect: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = context.coordinator
        tf.textAlignment = .center
        tf.font = UIFont.systemFont(ofSize: 50)
        tf.placeholder = "😊"
        tf.borderStyle = .none
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tf.becomeFirstResponder()
        }
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextField

        init(_ parent: EmojiTextField) { self.parent = parent }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard !string.isEmpty else { return true }
            let emoji = String(string.prefix(1))
            parent.selectedEmoji = emoji
            textField.text = emoji
            textField.resignFirstResponder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.parent.onSelect()
            }
            return false
        }
    }
}
