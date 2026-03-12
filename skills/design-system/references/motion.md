# Motion Tokens

## Values

```json
{
  "duration": {
    "instant": { "$value": "100ms", "$type": "duration" },
    "fast":    { "$value": "200ms", "$type": "duration" },
    "normal":  { "$value": "300ms", "$type": "duration" },
    "slow":    { "$value": "500ms", "$type": "duration" }
  },
  "easing": {
    "default": { "$value": "cubic-bezier(0.4, 0, 0.2, 1)", "$type": "cubicBezier" },
    "enter":   { "$value": "cubic-bezier(0, 0, 0.2, 1)",   "$type": "cubicBezier" },
    "exit":    { "$value": "cubic-bezier(0.4, 0, 1, 1)",    "$type": "cubicBezier" },
    "spring":  { "$value": "cubic-bezier(0.175, 0.885, 0.32, 1.275)", "$type": "cubicBezier" }
  }
}
```

## When to Use What

| Duration | Easing | Use Case |
|----------|--------|----------|
| `instant` | `default` | Toggle, checkbox, radio, switch |
| `fast` | `default` | Hover states, tooltips, color changes |
| `fast` | `enter` | Small elements appearing (badge, dot) |
| `normal` | `enter` | Modals opening, drawers sliding in, dropdown menus |
| `normal` | `exit` | Modals closing, elements dismissing |
| `normal` | `spring` | Playful bounces (use sparingly) |
| `slow` | `enter` | Page transitions, complex choreography |

## Reduced Motion

Non-negotiable. `prefers-reduced-motion: reduce` → skip animation entirely, don't just shorten duration.

Platform-specific implementation (CSS `@media`, reanimated `useReducedMotion`, etc.) belongs in each platform skill.

## Principle

Animation should communicate, not decorate. If removing an animation makes the interaction confusing (modal appearing from nowhere), keep it. If it's purely aesthetic (background shimmer), make it optional.
