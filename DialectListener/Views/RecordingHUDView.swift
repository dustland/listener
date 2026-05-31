import SwiftUI

/// Active recording overlay displayed on iPhone.
/// Provides a dedicated, low-light optimized HUD to check stopwatch, tap bookmarks, and stop.
public struct RecordingHUDView: View {
    
    @Bindable var sessionManager: SessionManager
    @State private var isWaveformAnimating = false
    
    public var body: some View {
        ZStack {
            // Absolute black background to fit street and subway low-profile use
            Color.black.ignoresSafeArea()
            
            // Atmospheric radial red glow
            RadialGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.15), Color.black]),
                center: .center,
                startRadius: 2,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // Status Top Bar
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .opacity(isWaveformAnimating ? 0.3 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isWaveformAnimating)
                        
                        Text("RECORDING SESSION")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .tracking(2)
                    }
                    
                    Text("Dialect Listener is recording surrounding audio...")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                
                // Large stopwatch timer
                Text(formatDuration(sessionManager.recorderManager.currentDuration))
                    .font(.system(size: 64, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .red.opacity(0.2), radius: 8)
                
                // Graphical audio wave animation
                HStack(spacing: 4) {
                    ForEach(0..<8) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom))
                            .frame(width: 6, height: isWaveformAnimating ? CGFloat.random(in: 12...68) : 24)
                            .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true).delay(Double(index) * 0.05), value: isWaveformAnimating)
                    }
                }
                .frame(height: 80)
                .onAppear {
                    isWaveformAnimating = true
                }

                LiveTranscriptPanel(
                    status: sessionManager.liveTranslationStatus,
                    lines: sessionManager.liveTranscriptLines
                )
                    .frame(maxHeight: .infinity)
                
                // Controls Group
                VStack(spacing: 16) {
                    // Massive Primary Bookmark Button
                    Button(action: {
                        sessionManager.addBookmark(at: sessionManager.recorderManager.currentDuration)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "bookmark.fill")
                                .font(.title2)
                            Text("Mark Unclear Phrase")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.85), Color.indigo.opacity(0.9)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .shadow(color: .blue.opacity(0.3), radius: 10)
                    }
                    .padding(.horizontal, 24)
                    
                    // Stopped Button
                    Button(action: {
                        sessionManager.stopSession()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                                .font(.body)
                                .foregroundColor(.red)
                            Text("Finish Session")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }

    // Format duration helper (mm:ss)
    private func formatDuration(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct LiveTranscriptPanel: View {
    let status: String
    let lines: [TranscriptLine]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(status, systemImage: "captions.bubble.fill")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.cyan)
                Spacer()
            }

            if lines.isEmpty {
                LiveTranscriptEmptyState()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(lines.suffix(8))) { line in
                                LiveTranscriptRow(line: line)
                            }
                        }
                    }
                    .onChange(of: lines.count) { _, _ in
                        if let last = lines.last {
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(18)
        .padding(.horizontal, 20)
    }
}

private struct LiveTranscriptEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 34))
                .foregroundColor(.white.opacity(0.25))
            Text("Live transcript will appear here as speech is detected.")
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LiveTranscriptRow: View {
    let line: TranscriptLine

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(line.dialectText)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(line.translationText.isEmpty ? "Translating..." : line.translationText)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(line.translationText.isEmpty ? .secondary : .cyan.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .id(line.id)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

#Preview {
    RecordingHUDView(sessionManager: SessionManager())
}
