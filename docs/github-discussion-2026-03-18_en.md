# Day 2 Progress: Documentation Architecture Decisions

## What We Accomplished Today

Major documentation cleanup and consistency fixes across 6 documents (~8,500 lines total).

## Key Decisions & Reasoning

### 1. Code Separation: PRD → Technical Spec

**Decision:** Moved ALL code blocks from design documents to technical-spec.md

**Why:**
- PRD/design docs should focus on *what* and *why*
- Technical spec focuses on *how*
- Easier maintenance: update code in one place
- Cleaner reading experience for non-technical stakeholders

**Impact:**
- design.md: ~1486 → 844 lines (-43%)
- design_en.md: ~1560 → 950 lines (-39%)

---

### 2. Desktop-Only Client Strategy

**Decision:** Removed Web Client, kept Desktop Client only

**Why:**
- Electron app already covers all platforms (macOS/Windows/Linux)
- Web client would require additional security considerations for browser-based key storage
- Reduces development scope by ~30%
- Users installing trading software typically prefer native apps

**Impact:**
- Clearer product positioning
- Focused development effort
- Removed 5 references across requirement.md and requirement_en.md

---

### 3. User Authentication: Two Distinct Flows

**Decision:** Separate "Registration/Login" from "Login/Logout"

| Flow | Location | Purpose |
|------|----------|---------|
| User Registration/Login | First-Run Wizard (Step 4) | New user onboarding |
| User Login/Logout | Settings Panel | Account switching |

**Why:**
- First-run wizard is for *initialization* (creating account)
- Settings panel is for *management* (switching accounts)
- Different UX contexts require different UI patterns
- Prevents confusion: "Why am I registering again?"

**Impact:**
- Clearer feature separation
- Better UX mapping

---

### 4. Document Consistency Standards

**Decision:** Enforce strict version synchronization

**Rules established:**
1. Chinese and English versions must have identical structure
2. Section numbers must be sequential (6.1 → 6.2 → 6.3, not 6.1 → 6.2 → 6.4)
3. All code references use format: `See [Technical Spec - Title](technical-spec_en.md#anchor)`

**Why:**
- Prevents "drift" between language versions
- Easier for contributors to maintain
- Professional appearance

**Impact:**
- Fixed 2 major structural inconsistencies today
- Established template for future documentation

---

## File Status Summary

| Document | Lines | Status |
|----------|-------|--------|
| requirement.md | 1,984 | ✅ Synced |
| requirement_en.md | 471 | ✅ Synced |
| design.md | 844 | ✅ Synced |
| design_en.md | 950 | ✅ Synced |
| technical-spec.md | 2,162 | ✅ Complete |
| technical-spec_en.md | 2,100 | ✅ Complete |

---

## Bonus: X Post Draft

Created a 275-character post for X highlighting our architecture philosophy:

```
Building a crypto trading AI that respects your privacy:

❌ What we DON'T do:
- Store your API keys
- Charge monthly fees
- Lock you in

✅ What we DO:
- Chat via Telegram
- Keep keys local (AES-256)
- Charge 10% ONLY on profit

Local-first = trust-first.

🚀 cryptoclaw.pro
```

---

## Next Steps

- [ ] Begin MVP development (Week 1-4)
- [ ] Set up CI/CD for documentation
- [ ] Create contribution guidelines

---

## Discussion

What documentation practices have worked well for your projects? Do you prefer:
1. Single comprehensive doc vs. multiple focused docs?
2. Code inline with design or separated?
3. How do you keep translations in sync?

---

*Progress log: Day 2 of #BuildInPublic*
*Repo: github.com/franklili3/CryptoQClaw*
*Follow: @cryptoclaw88*
