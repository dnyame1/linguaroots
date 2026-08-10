import SwiftUI
import UIKit

// MARK: - Design Tokens

enum Design {
    static let hPad: CGFloat = 24
    static let cardRadius: CGFloat = 16
    static let buttonRadius: CGFloat = 16
    static let buttonHeight: CGFloat = 56
}

// MARK: - Color(hex:) helper
// NOTE: Color(hex:) is already defined elsewhere in this project (that's why
// the original file could call it without defining it here). Intentionally
// not redeclaring it in this file — if you ever get an "Invalid redeclaration"
// error again, search the project for another `extension Color { init(hex:` .

// MARK: - Haptics

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    static func select() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Onboarding State

enum OnboardingStep: Int, CaseIterable {
    case splash, goal, language, name, welcome

    /// Splash and Welcome are "bookend" screens and don't count toward the
    /// progress bar the user sees while making choices.
    var progressIndex: Int? {
        switch self {
        case .splash: return nil
        case .goal: return 0
        case .language: return 1
        case .name: return 2
        case .welcome: return nil
        }
    }
    static var progressSteps: Int { 3 }
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var step: OnboardingStep = .splash
    @State private var selectedGoal: String = ""
    @State private var selectedLanguage: String = "Twi"
    @State private var nameInput: String = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.6), value: step)

            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 320, height: 320)
                    .offset(x: geo.size.width * 0.6, y: -60)
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 200, height: 200)
                    .offset(x: -40, y: geo.size.height * 0.75)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Top bar: back button + progress
                if let progress = step.progressIndex {
                    TopBar(
                        progress: progress,
                        total: OnboardingStep.progressSteps,
                        showBack: step != .goal,
                        onBack: goBack
                    )
                    .padding(.top, 8)
                    .transition(.opacity)
                }

                Group {
                    switch step {
                    case .splash:
                        SplashScreen(onContinue: advance)
                    case .goal:
                        GoalScreen(selectedGoal: $selectedGoal, onContinue: advance)
                    case .language:
                        LanguageScreen(selectedLanguage: $selectedLanguage, onContinue: advance)
                    case .name:
                        NameScreen(nameInput: $nameInput, onContinue: advance)
                    case .welcome:
                        WelcomeScreen(name: nameInput, goal: selectedGoal) {
                            Haptics.success()
                            UserDefaults.standard.set(nameInput, forKey: "userName")
                            UserDefaults.standard.set(selectedGoal, forKey: "userGoal")
                            onComplete()
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: step)
            }
        }
    }

    var backgroundColors: [Color] {
        switch step {
        case .splash:   return [Color(hex: "1a1a2e"), Color(hex: "16213e")]
        case .goal:     return [Color(hex: "0f3460"), Color(hex: "1a1a2e")]
        case .language: return [Color(hex: "533483"), Color(hex: "0f3460")]
        case .name:     return [Color(hex: "e94560"), Color(hex: "533483")]
        case .welcome:  return [Color(hex: "f5a623"), Color(hex: "e94560")]
        }
    }

    func advance() {
        Haptics.tap()
        withAnimation {
            switch step {
            case .splash:   step = .goal
            case .goal:     step = .language
            case .language: step = .name
            case .name:     step = .welcome
            case .welcome:  break
            }
        }
    }

    func goBack() {
        Haptics.select()
        withAnimation {
            switch step {
            case .splash, .goal: break
            case .language: step = .goal
            case .name:     step = .language
            case .welcome:  step = .name
            }
        }
    }
}

// MARK: - Top Bar (Back + Progress)

struct TopBar: View {
    let progress: Int
    let total: Int
    let showBack: Bool
    var onBack: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .opacity(showBack ? 1 : 0)
            .disabled(!showBack)
            .accessibilityLabel("Back")

            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { i in
                    Capsule()
                        .fill(Color.white.opacity(i <= progress ? 0.9 : 0.2))
                        .frame(height: 5)
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
        }
        .padding(.horizontal, Design.hPad)
        .frame(height: 44)
    }
}

// MARK: - Reusable Primary Button

struct PrimaryButton: View {
    let title: String
    var trailingSystemImage: String? = "arrow.right"
    let isEnabled: Bool
    let tint: Color
    let action: () -> Void

    init(_ title: String, trailingSystemImage: String? = "arrow.right", isEnabled: Bool = true, tint: Color, action: @escaping () -> Void) {
        self.title = title
        self.trailingSystemImage = trailingSystemImage
        self.isEnabled = isEnabled
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                if let icon = trailingSystemImage {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(isEnabled ? tint : Color.white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .frame(height: Design.buttonHeight)
            .background(isEnabled ? Color.white : Color.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: Design.buttonRadius, style: .continuous))
            .padding(.horizontal, Design.hPad + 8)
            .shadow(color: isEnabled ? Color.black.opacity(0.15) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Screen 1: Splash

struct SplashScreen: View {
    var onContinue: () -> Void
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var buttonOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 120, height: 120)
                Text("🌱")
                    .font(.system(size: 60))
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            Spacer().frame(height: 32)

            Text("LinguaRoots")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .opacity(logoOpacity)

            Spacer().frame(height: 16)

            Text("Millions of Ghanaian diaspora kids are growing up\nwithout their mother tongue.\nLinguaRoots was built to change that,\none word at a time.")
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .opacity(taglineOpacity)

            Spacer()

            PrimaryButton("Begin Your Journey", tint: Color(hex: "1a1a2e"), action: onContinue)
                .opacity(buttonOpacity)

            Spacer().frame(height: 48)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                logoScale = 1.0; logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.7)) { taglineOpacity = 1.0 }
            withAnimation(.easeOut(duration: 0.5).delay(1.2)) { buttonOpacity = 1.0 }
        }
    }
}

// MARK: - Screen 2: Goal Picker

struct GoalScreen: View {
    @Binding var selectedGoal: String
    var onContinue: () -> Void

    let goals: [(emoji: String, title: String, subtitle: String)] = [
        ("🫂", "Reconnect with my roots", "Speak the language of home"),
        ("✈️", "Travel to Ghana", "Get by confidently when you arrive"),
        ("💬", "Connect with family", "Talk to grandparents, aunties, cousins"),
        ("🌍", "Just curious", "Explore a beautiful language")
    ]
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 24)
            Text("What's your goal?")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, Design.hPad + 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            Spacer().frame(height: 8)
            Text("We'll shape your learning around it.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .padding(.horizontal, Design.hPad + 8)
                .opacity(appeared ? 1 : 0)
            Spacer().frame(height: 32)
            VStack(spacing: 14) {
                ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                    GoalCard(
                        emoji: goal.emoji,
                        title: goal.title,
                        subtitle: goal.subtitle,
                        isSelected: selectedGoal == goal.title
                    ) {
                        Haptics.select()
                        selectedGoal = goal.title
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.08 + 0.2), value: appeared)
                }
            }
            .padding(.horizontal, Design.hPad)
            Spacer()
            PrimaryButton("Continue", isEnabled: !selectedGoal.isEmpty, tint: Color(hex: "0f3460"), action: onContinue)
            Spacer().frame(height: 32)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { appeared = true } }
    }
}

struct GoalCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                            .stroke(isSelected ? Color.white.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Screen 3: Language Picker

struct LanguageScreen: View {
    @Binding var selectedLanguage: String
    var onContinue: () -> Void

    let languages: [(flag: String, name: String, region: String, available: Bool)] = [
        ("🇬🇭", "Twi", "Akan · Ghana", true),
        ("🇳🇬", "Yoruba", "Nigeria", false),
        ("🇿🇦", "Zulu", "South Africa", false),
        ("🇸🇳", "Wolof", "Senegal", false),
        ("🇪🇹", "Amharic", "Ethiopia", false),
        ("🇹🇿", "Swahili", "East Africa", false),
    ]
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 24)
            Text("Pick your language")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, Design.hPad + 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            Spacer().frame(height: 8)
            Text("More African languages coming soon.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .padding(.horizontal, Design.hPad + 8)
                .opacity(appeared ? 1 : 0)
            Spacer().frame(height: 32)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(languages.enumerated()), id: \.offset) { index, lang in
                        LanguageCard(
                            flag: lang.flag, name: lang.name, region: lang.region,
                            available: lang.available, isSelected: selectedLanguage == lang.name
                        ) {
                            if lang.available {
                                Haptics.select()
                                selectedLanguage = lang.name
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(Double(index) * 0.07 + 0.15), value: appeared)
                    }
                }
                .padding(.horizontal, Design.hPad)
            }
            Spacer()
            PrimaryButton("Continue", tint: Color(hex: "533483"), action: onContinue)
            Spacer().frame(height: 32)
        }
        .onAppear { withAnimation(.easeOut(duration: 0.4)) { appeared = true } }
    }
}

struct LanguageCard: View {
    let flag: String
    let name: String
    let region: String
    let available: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(flag).font(.system(size: 28))
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(available ? .white : .white.opacity(0.35))
                    Text(region)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(available ? .white.opacity(0.6) : .white.opacity(0.25))
                }
                Spacer()
                if !available {
                    Text("Soon")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                            .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!available)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(available ? "" : "Coming soon")
    }
}

// MARK: - Screen 4: Name Input

struct NameScreen: View {
    @Binding var nameInput: String
    var onContinue: () -> Void
    @FocusState private var isFocused: Bool
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 24)
            Text("What's your name?")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, Design.hPad + 8)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            Spacer().frame(height: 8)
            Text("We'll make this feel personal.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .padding(.horizontal, Design.hPad + 8)
                .opacity(appeared ? 1 : 0)
            Spacer().frame(height: 40)
            VStack(alignment: .leading, spacing: 8) {
                Text("YOUR NAME")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)
                    .padding(.horizontal, Design.hPad + 8)
                TextField("e.g. Ama, Kofi, Abena…", text: $nameInput)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .tint(.white)
                    .submitLabel(.done)
                    .onSubmit { isFocused = false; onContinue() }
                    .padding(20)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Design.cardRadius, style: .continuous)
                            .stroke(isFocused ? Color.white.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
                    .padding(.horizontal, Design.hPad)
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.2), value: appeared)
            Spacer()
            PrimaryButton(
                nameInput.isEmpty ? "Skip" : "Continue",
                tint: Color(hex: "e94560")
            ) {
                isFocused = false
                onContinue()
            }
            Spacer().frame(height: 32)
        }
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true }
        }
    }
}

// MARK: - Screen 5: Welcome

struct WelcomeScreen: View {
    let name: String
    let goal: String
    var onFinish: () -> Void

    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0
    @State private var emojiOffset: CGFloat = 30
    @State private var buttonVisible = false

    var displayName: String {
        name.trimmingCharacters(in: .whitespaces).isEmpty ? "friend" : name
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("🌍")
                .font(.system(size: 80))
                .offset(y: emojiOffset)
                .opacity(opacity)
            Spacer().frame(height: 28)
            VStack(spacing: 12) {
                Text("Akwaaba, \(displayName)!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("Akwaaba means 'welcome' in Twi.\nYour journey starts right now.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            Spacer().frame(height: 16)
            if !goal.isEmpty {
                Text("Goal: \(goal)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.horizontal, 20).padding(.vertical, 8)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                    .opacity(opacity)
            }
            Spacer()
            PrimaryButton("Start Learning", trailingSystemImage: nil, tint: Color(hex: "e94560")) {
                onFinish()
            }
            .opacity(buttonVisible ? 1 : 0)
            .offset(y: buttonVisible ? 0 : 20)
            Spacer().frame(height: 48)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.1)) {
                scale = 1.0; opacity = 1.0; emojiOffset = 0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
                buttonVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
