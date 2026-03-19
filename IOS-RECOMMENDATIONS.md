# AI agents can build iOS apps that compile — here's the complete playbook

**The core breakthrough for agent-driven iOS development is closing the feedback loop.** When Claude Code can build your project, see errors, install on a simulator, and capture screenshots — all without Xcode's GUI — the success rate jumps dramatically. The stack that makes this work: **XcodeGen** (to avoid .pbxproj corruption), **XcodeBuildMCP** (to give Claude structured build output), **`xcodebuild` + `xcrun simctl`** (for headless builds and simulator control), and **SwiftUI** (the most agent-friendly UI framework). For a 2D grid puzzle game like Damaze, pure SwiftUI beats SpriteKit on every dimension that matters to an AI agent. GasTown, Steve Yegge's multi-agent orchestrator, can coordinate 20–30 Claude Code instances on larger projects.

---

## GasTown orchestrates armies of Claude Code agents

**GasTown is a multi-agent orchestration system** created by Steve Yegge, launched January 1, 2026 via Medium. It coordinates **20–30 parallel AI coding agents** — primarily Claude Code instances, but also supporting Codex, Gemini CLI, and others. The project lives at `github.com/steveyegge/gastown` with **~8,800 stars**, is written in Go, and licensed under MIT.

GasTown uses an elaborate industrial-town metaphor. The **Mayor** is your primary Claude Code instance that orchestrates all others. **Rigs** are project containers wrapping git repos. **Polecats** are worker agents with persistent identity but ephemeral sessions. **Beads** (a companion project) provides git-backed issue tracking. **Formulas** define reusable TOML workflow templates. The system's core principle — **GUPP** ("If there is work on your hook, YOU MUST RUN IT") — ensures work survives agent crashes and session restarts by persisting state in git-backed hooks.

Installation is straightforward: `brew install gastown`, `npm install -g @gastown/gt`, or build from source with Go 1.24+. Prerequisites include Git 2.20+, Dolt ≥1.82.4, the Beads CLI, and optionally tmux 3.0+ for the multi-pane agent UI.

**GasTown is not iOS-specific** — it's platform-agnostic. Any git repository can be a "rig." For iOS development, you'd configure formulas that invoke `xcodebuild`, `xcrun simctl`, and other CLI tools.

GasTown becomes valuable when your project has many independent modules where parallelism pays off.

---

## The toolchain that makes agent-built iOS apps actually compile

The single biggest productivity unlock is **XcodeBuildMCP** (maintained by Sentry), which provides **59 structured tools** for builds, tests, simulator control, LLDB debugging, and UI automation — all returning clean JSON instead of raw `xcodebuild` output. This reduces token consumption by **87%** compared to parsing verbose build logs. Install it with `npm install -g xcodebuildmcp@latest`.

For agents working purely from the terminal, the essential commands form a reliable pipeline:

**Building for simulator with signing disabled:**
```bash
xcodebuild -scheme MyApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | xcsift
```

The three `CODE_SIGNING` flags are the definitive solution to provisioning headaches. Simulator builds **never** require an Apple Developer account. The `xcsift` tool at the end converts build output into structured JSON with file paths, line numbers, and error messages — ideal for an agent to parse and fix automatically.

**Simulator management follows a simple lifecycle:**
```bash
xcrun simctl boot "iPhone 15"
xcrun simctl install booted /path/to/MyApp.app
xcrun simctl launch booted com.example.myapp
sleep 3
xcrun simctl io booted screenshot ./screenshot.png
xcrun simctl shutdown all
```

Since Xcode 9, **tests run headlessly by default** — no visible simulator window needed. This works in CI environments like GitHub Actions (which provide macOS runners with Xcode pre-installed) and on local machines where the Simulator.app isn't open. The one caveat: macOS needs an Aqua (graphical) session active, which CI services handle automatically.

For build output parsing beyond xcsift, **xcbeautify** (`brew install xcbeautify`) provides human-readable formatting with CI-specific renderers for GitHub Actions and TeamCity. For test results, `xcodebuild test` produces `.xcresult` bundles that can be inspected programmatically.

---

## Why XcodeGen eliminates the #1 agent failure mode

The `.pbxproj` file — buried inside every `.xcodeproj` bundle — is the single greatest source of agent-induced build failures. It uses an archaic OpenStep plist format where every file, build phase, and configuration cross-references **96-bit UUIDs**. Adding one Swift file requires editing 4+ sections simultaneously. A single misplaced semicolon corrupts the entire project. Even modest projects produce **22,000+ line** .pbxproj files that are practically unreadable.

**XcodeGen solves this completely.** Agents write a simple YAML file; `xcodegen generate` produces a valid `.xcodeproj`. The `.xcodeproj` goes in `.gitignore` — it's regenerated on every build. Source files placed in directories are auto-discovered, so agents never need to register new files in any project configuration.

A minimal `project.yml` for an iOS puzzle game:
```yaml
name: Damaze
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "16.0"
targets:
  Damaze:
    type: application
    platform: iOS
    sources: [Sources]
    resources: [Resources]
    settings:
      base:
        CODE_SIGNING_ALLOWED: false
        GENERATE_INFOPLIST_FILE: true
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: 1
```

Install with `brew install xcodegen`. **Tuist** is the alternative (Swift-based configuration, more features like binary caching), but XcodeGen's YAML format is more universally agent-friendly.

The complete agent workflow becomes: write Swift files → update `project.yml` if needed → run `xcodegen generate` → run `xcodebuild` → install and screenshot on simulator. Each step produces parseable output. No opaque binary files involved.

---

## SwiftUI is the clear winner for agent-generated iOS code

**SwiftUI's declarative syntax maps naturally to how LLMs generate code** — describe *what* the UI should look like, not *how* to build it imperatively. A complete SwiftUI view is 10–20 lines versus 50–100+ for equivalent UIKit. There are no storyboard or XIB files (XML formats that agents corrupt easily), no delegate patterns to get wrong, and state management is declarative with `@State`, `@Binding`, and `@Observable`.

Real-world results confirm this. Indragie Karunaratne shipped a **20,000-line macOS app** built almost entirely by Claude Code, writing fewer than 1,000 lines by hand. Pato Lankenau went from first prompt to **App Store submission in ~8 hours** with minimal prior iOS experience. Tom Wentworth shipped **4 apps to the App Store** with zero Swift knowledge. The Vinylogue rewrite — 5,609 lines across 52 files — took 7 calendar days for $20 on the Anthropic Pro plan.

However, Claude Code has well-documented failure patterns with SwiftUI. It defaults to **iOS 16-era patterns**: `@StateObject` with `ObservableObject` instead of the modern `@Observable` macro, deprecated modifiers like `foregroundColor()` instead of `foregroundStyle()`, old `NavigationView` instead of `NavigationStack`, and the single-parameter `onChange()` variant. Paul Hudson's open-source **SwiftUI Agent Skill** (`npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro`) automatically corrects these patterns. The **SwiftAgents AGENTS.md template** provides project-level guardrails.

The most critical setup step is creating a comprehensive **CLAUDE.md** file in your project root documenting: the scheme name and workspace path, simulator UDID, architecture preferences, which MCP tools to use, and explicit instructions to prefer modern SwiftUI APIs.

For teams considering alternatives: **Expo/React Native** is the fastest path if you don't need native iOS APIs. AI agents generate more accurate TypeScript than Swift (larger training corpus), Expo's Continuous Native Generation auto-generates native projects, and EAS Build handles code signing in the cloud. But for a native iOS game, SwiftUI wins.

---

## Pure SwiftUI beats SpriteKit for a Damaze-style puzzle game

Damaze is a grid-based puzzle where a ball moves in a swiped direction until hitting a wall, coloring each cell it crosses. The goal: fill every cell. This requires **grid rendering, swipe detection, cell coloring animation, and simple state tracking**. No physics engine, no particle systems, no real-time game loop.

**SwiftUI handles every requirement with minimal code.** Grid rendering uses `LazyVGrid` or simple `ForEach` in `VStack`/`HStack`. Swipe detection uses `DragGesture` with direction calculated from translation. Cell coloring animates with `withAnimation { grid[row][col] = .filled }`. Ball movement animates with `.offset()` transitions. The entire game model is a `@Observable` class wrapping a 2D array — trivially unit-testable with XCTest.

SpriteKit is overkill. It adds SKScene/SKNode hierarchy complexity, requires manual coordinate-based layout ("you have to do everything with screen coordinates," per developer Ben Congdon), generates extra template files (.sks, GameViewController) that confuse agents, and needs **400–800 lines** for what SwiftUI does in **200–400**. Apple's own treatment of SpriteKit feels "a bit neglected" according to community consensus.

The optimal architecture separates concerns cleanly:

- **`GameGrid.swift`** — Pure Swift 2D array with move logic, win-condition checking. Zero UI dependencies. Fully testable.
- **`Level.swift`** — `Codable` level definitions loadable from JSON. Agents can generate level data programmatically.
- **`GameView.swift`** — SwiftUI grid display using `ForEach` + gesture handling. Thin UI layer.
- **`CellView.swift`** — Individual cell with color animation via `.background(state.color).animation(.easeInOut)`.

Cross-platform game engines (Unity, Godot, Flutter+Flame) all add unnecessary complexity for this use case. Unity produces **150MB+ binaries** for a simple puzzle. Godot requires a separate editor and export configuration. None are more agent-friendly than native SwiftUI for an iOS-only target. If sophisticated animations are later needed (particle effects on level completion), a single `SpriteView` can be embedded within the SwiftUI hierarchy — a well-documented hybrid approach.

---

## Solving every pain point the user has experienced

**Xcode project config/build errors:** Eliminate `.pbxproj` manipulation entirely with XcodeGen. Agent modifies only Swift source files and a YAML configuration. Run `xcodegen generate` before every build. Use Xcode's folder-based file references (not Groups) so new files are auto-discovered without any project file changes.

**Signing/provisioning issues:** Three xcodebuild flags solve this permanently for simulator builds: `CODE_SIGN_IDENTITY=""`, `CODE_SIGNING_REQUIRED=NO`, `CODE_SIGNING_ALLOWED=NO`. Simulator builds never require an Apple Developer account. Set `CODE_SIGNING_ALLOWED: false` in your XcodeGen `project.yml` so it's always baked in.

**Agents can't run the simulator:** Use `xcrun simctl boot`, `install`, `launch`, and `io booted screenshot` from the terminal. XcodeBuildMCP wraps all of this into structured MCP tools that Claude Code can call directly. Cache the simulator UDID in CLAUDE.md to avoid repeated lookups. Tests run headlessly by default since Xcode 9.

**Code that doesn't compile:** Use xcsift (`brew install xcsift`) to pipe `xcodebuild` output into structured JSON with exact file paths and line numbers. Feed these directly back to Claude. Install Paul Hudson's SwiftUI Agent Skill to prevent deprecated API usage. Maintain an AGENTS.md with project-specific coding standards. Target iOS 16.0+ minimum to avoid availability annotation issues while accessing modern SwiftUI features.

**Agent getting stuck in loops:** Commit after every successful Claude interaction cycle. Use `git diff` to review changes before accepting them. When Claude spends more than 2–3 iterations on a problem, intervene with specific guidance or abandon the approach. Use plan mode (Shift+Tab in Claude Code) for complex features before letting the agent code.

---

## Conclusion

The gap between "AI agent writes iOS code" and "code actually builds and runs" is bridged by tooling, not model capability. **XcodeGen + XcodeBuildMCP + xcsift** form the critical infrastructure layer that turns Claude Code from a code generator into a functional iOS developer. SwiftUI's declarative paradigm aligns with how language models think, and for a grid-based puzzle game, it provides everything needed without SpriteKit's overhead.

GasTown represents the frontier of multi-agent orchestration — coordinating dozens of Claude instances on a single project. Combined with proper CLI tooling, it enables building, testing, and iterating on an iOS puzzle game efficiently.

The most actionable insight from community experience: **treat the agent as a very fast junior developer, not an autonomous architect.** Provide clear CLAUDE.md instructions, commit frequently, keep prompts focused on single features, and always verify builds through the CLI pipeline rather than trusting the agent's self-assessment.
