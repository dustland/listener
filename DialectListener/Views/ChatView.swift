import SwiftUI
import AVFoundation

public struct ChatView: View {
    @Bindable var settings: AppSettings
    @State private var inputText = ""
    @State private var result: DialectChatResult?
    @State private var isTranslating = false
    @State private var isPressingVoice = false
    @State private var statusText: String?
    @State private var dictationManager = MandarinDictationManager()
    @State private var speechSynthesizer = AVSpeechSynthesizer()

    public init(settings: AppSettings) {
        self.settings = settings
    }

    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.08), Color.black]),
                center: .topTrailing,
                startRadius: 2,
                endRadius: 520
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                ScrollView {
                    resultPanel
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .top)
                }

                inputPanel
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(.black.opacity(0.72))
            }
        }
        .onChange(of: dictationManager.transcript) { _, newValue in
            guard dictationManager.isRecording else { return }
            inputText = newValue
        }
        .onDisappear {
            dictationManager.stop()
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppText.t("Chat", "畅聊"))
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Label(AppText.t("Mandarin", "普通话"), systemImage: "text.quote")
                    Text("->")
                        .foregroundColor(.secondary)
                    Label(settings.chatTargetDialect.title, systemImage: "bubble.left.and.bubble.right.fill")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            }

            Spacer()

            Text(settings.aiModel.title)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
        }
    }

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                TextEditor(text: $inputText)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 42, maxHeight: 104)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isPressingVoice ? Color.cyan.opacity(0.6) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .cornerRadius(18)
                    .overlay(alignment: .topLeading) {
                        if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(isPressingVoice ? AppText.t("Release to send", "松开发送") : AppText.t("Type, or hold the mic to speak.", "输入文字，或按住麦克风说话。"))
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }

                inputActionButton
            }

            if let statusText {
                Text(statusText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var inputActionButton: some View {
        if isTranslating {
            ProgressView()
                .tint(.black)
                .frame(width: 44, height: 44)
                .background(Color.cyan)
                .clipShape(Circle())
        } else if canTranslate {
            Button(action: translate) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.cyan)
                    .clipShape(Circle())
            }
        } else {
            Image(systemName: isPressingVoice ? "waveform" : "mic.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(isPressingVoice ? .black : .cyan)
                .frame(width: 44, height: 44)
                .background(isPressingVoice ? Color.cyan : Color.white.opacity(0.08))
                .clipShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            beginVoiceMessage()
                        }
                        .onEnded { _ in
                            finishVoiceMessage()
                        }
                )
        }
    }

    private var resultPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let result {
                messageBubble(title: AppText.t("You", "你"), text: result.mandarinText, isUser: true)
                messageBubble(title: settings.chatTargetDialect.title, text: result.dialectText, isUser: false)
                resultBlock(title: AppText.t("Pronunciation", "发音"), text: result.pronunciation, prominent: false)
                resultBlock(title: AppText.t("Note", "提示"), text: result.usageNote, prominent: false)

                playButton
            } else {
                Text(AppText.t("Send a Mandarin phrase to get a dialect version and pronunciation.", "发送一句普通话，获取方言说法和发音。"))
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 260, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var playButton: some View {
        Button(action: speakResult) {
            Label(AppText.t("Play", "播放"), systemImage: "speaker.wave.2.fill")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.white.opacity(0.08))
                .foregroundColor(.white)
                .cornerRadius(14)
        }
    }

    private func messageBubble(title: String, text: String, isUser: Bool) -> some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(isUser ? .black : .white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(13)
                .background(isUser ? Color.cyan : Color.white.opacity(0.08))
                .cornerRadius(16)
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private func resultBlock(title: String, text: String, prominent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(prominent ? .title3 : .body, design: .rounded))
                .fontWeight(prominent ? .bold : .regular)
                .foregroundColor(prominent ? .white : .cyan.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var canTranslate: Bool {
        !isTranslating && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func beginVoiceMessage() {
        guard !isPressingVoice, !dictationManager.isRecording else { return }
        isPressingVoice = true
        inputText = ""
        statusText = AppText.t("Listening for Mandarin...", "正在听普通话...")

        Task {
            let granted = await dictationManager.requestAuthorization()
            guard granted else {
                await MainActor.run {
                    isPressingVoice = false
                    statusText = AppText.t("Microphone or speech permission is missing.", "缺少麦克风或语音识别权限。")
                }
                return
            }

            do {
                try dictationManager.start()
            } catch {
                await MainActor.run {
                    isPressingVoice = false
                    statusText = error.localizedDescription
                }
            }
        }
    }

    private func finishVoiceMessage() {
        guard isPressingVoice else { return }
        isPressingVoice = false
        dictationManager.stop()

        Task {
            try? await Task.sleep(for: .milliseconds(250))
            await MainActor.run {
                let spokenText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !spokenText.isEmpty else {
                    statusText = AppText.t("No Mandarin recognized.", "没有识别到普通话。")
                    return
                }
                translate()
            }
        }
    }

    private func translate() {
        dictationManager.stop()
        statusText = nil
        isTranslating = true

        Task {
            do {
                let chatService = DialectChatService(model: settings.aiModel.modelIdentifier)
                let translated = try await chatService.translateMandarin(
                    inputText,
                    to: settings.chatTargetDialect
                )
                await MainActor.run {
                    result = translated
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    statusText = error.localizedDescription
                    isTranslating = false
                }
            }
        }
    }

    private func speakResult() {
        guard let result else { return }
        speechSynthesizer.stopSpeaking(at: .immediate)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            statusText = error.localizedDescription
            return
        }

        let utterance = AVSpeechUtterance(string: result.dialectText)
        guard let voice = AVSpeechSynthesisVoice(language: settings.chatTargetDialect.speechLocaleIdentifier) else {
            statusText = AppText.t("No compatible system voice found.", "没有找到可用的系统语音。")
            return
        }
        utterance.voice = voice
        utterance.rate = 0.45
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    ChatView(settings: AppSettings())
}
