---
name: code-writer
description: Generates clean, functional, and well-structured source code based on technical specifications or feature requests. Trigger this skill whenever a user asks to write a script, build a function, implement a feature, scaffold a component, or generate a full code file from scratch.
---

# Code Writer Skill

## Trigger Conditions
* The user provides feature requirements and asks for code.
* The user requests specific functions, classes, API endpoints, or database schemas.
* The user says phrases like "Write a script to...", "Create a component for...", or "Implement this algorithm in [language]".

## Process Steps
1. **Gather Requirements:** Identify the target programming language, required frameworks, and any external dependencies.
2. **Architecture Blueprint:** Outline the logical structure of the solution (modules, data structures, and algorithms) before typing the code.
3. **Draft Implementation:** Write clear, concise, and modern code that addresses all functional requirements.
4. **Error Handling:** Embed robust validation, exception catching, and edge-case handling into the logic.
5. **Documentation:** Add meaningful inline comments for complex logic and standard docstrings for public functions/methods.

## Guidelines & Guardrails
* **Do:** Write modular, DRY (Don't Repeat Yourself), and testable code.
* **Do:** Use modern language features and community-standard design patterns.
* **Do Not:** Use deprecated libraries, unsafe functions, or hardcoded configurations.
* **Do Not:** Provide partial code blocks or placeholders (like `// TODO: implement later`) unless explicitly requested.

## Output Format
Structure your response cleanly, leading directly with the solution description followed by the implementation:

### 🛠️ Architecture Summary
* Briefly explain the technical approach, architecture, and required dependencies.

### 💻 Code Implementation
```[language]
// Present the complete, functional, and copy-pasteable code here
```

### 🧪 Usage & Testing
* Provide a minimal, concrete example showing how to run, call, or test the generated code.
* Never include emdash characters or emojis in the comments or code snippets, as they may cause syntax errors in some programming languages.
