# COMMUNIO DEVELOPMENT STANDARDS

Version: 1.0
Project: Communio
Platform: Flutter
Backend: Supabase
Architecture: Feature First + Clean Architecture

---

# PROJECT VISION

Communio is a premium digital platform for Religious Congregations.

The application should feel like a combination of:

- Apple
- Notion
- Stripe
- GEMS Education
- Google Workspace

Every screen must feel elegant, spacious, premium and timeless.

Never create clutter.

White space is a feature.

---

# DESIGN PHILOSOPHY

Always follow these principles.

• Clean
• Minimal
• Premium
• Elegant
• Accessible
• Responsive
• Fast
• Modern

Animations should be subtle.

Avoid unnecessary decoration.

---

# COLOR PALETTE

Primary
Navy Blue

Accent
Gold

Background
Warm White

Cards
Pure White

Success
Green

Warning
Amber

Error
Red

---

# TYPOGRAPHY

Primary Font

Inter

Headings

Cormorant Garamond

Never use random font sizes.

Always use AppTypography.

---

# SPACING

Always use

AppSpacing

Never hardcode spacing values.

---

# COLORS

Always use

AppColors

Never use Color(...) directly.

---

# SHADOWS

Always use

AppShadows.sm

AppShadows.md

AppShadows.lg

Never write BoxShadow directly.

---

# RADIUS

Always use AppRadius.

---

# ASSETS

Never hardcode image paths.

Always use AppAssets.

---

# RESPONSIVE DESIGN

Desktop

1440+

Tablet

768–1439

Mobile

0–767

Every screen must support all three.

---

# LOGIN SCREEN

Desktop

Background artwork

Centered login card

Large branding

Tablet

Same layout

Reduced spacing

Mobile

Inspired by premium banking apps

Background visible

Rounded login card

Large logo

Elegant animations

---

# ANIMATIONS

Maximum duration

300ms

Fade

Scale

Slide

No flashy animations.

---

# CODE STYLE

Small reusable widgets.

Maximum widget length

250 lines.

Never duplicate code.

Extract reusable components.

---

# FOLDER STRUCTURE

lib/

app/

core/

features/

shared/

Every feature owns

models

screens

services

widgets

---

# CODING RULES

Never break existing code.

Always preserve theme.

Always preserve responsiveness.

Always preserve accessibility.

Run flutter analyze before finishing.

Never ignore analyzer errors.

---

# UI STANDARD

Every screen must look production quality.

Every button

Rounded

Elevation

Hover (desktop)

Ripple

Loading state

Disabled state

---

# PERFORMANCE

Prefer const.

Avoid rebuilds.

Lazy load where possible.

Optimize images.

---

# GIT

Small commits.

Meaningful commit messages.

Never commit broken code.

---

# GOAL

Communio should be the highest-quality congregation management application available on Flutter.