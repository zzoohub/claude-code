# shadcn/ui + cva + Radix Primitives Integration

shadcn isn't a library — it's a code-gen tool that copies components into your repo. Tokens flow through CSS variables; variants are built with `class-variance-authority` (cva); accessibility comes from Radix Primitives.

## Stack

| Layer | Tool |
|---|---|
| Headless primitives | `@radix-ui/react-*` (Dialog, Popover, Select, etc.) |
| Variants | `class-variance-authority` (cva) |
| Class merging | `tailwind-merge` + `clsx` (exposed as `cn()`) |
| Tokens | Tailwind v4 `@theme` reading project CSS variables |
| Generator | `npx shadcn@latest add <component>` |

## File layout (FSD-aware)

```
shared/ui/
├── button.tsx           # shadcn-generated, owned by us
├── dialog.tsx           # shadcn-generated, owned by us
└── lib/
    └── cn.ts            # cn helper
```

## The `cn` helper

```ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## Button with cva (reads design tokens via Tailwind classes)

```tsx
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/shared/ui/lib/cn';
import { Slot } from '@radix-ui/react-slot';

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 disabled:opacity-50',
  {
    variants: {
      variant: {
        primary: 'bg-interactive-primary text-white hover:bg-interactive-primary-hover',
        secondary: 'border border-border bg-bg-secondary hover:bg-bg-secondary-hover',
        danger: 'bg-status-error text-white hover:bg-status-error-hover',
        ghost: 'hover:bg-bg-secondary',
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        md: 'h-10 px-4',
        lg: 'h-12 px-6 text-lg',
      },
    },
    defaultVariants: { variant: 'primary', size: 'md' },
  }
);

interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

export function Button({ className, variant, size, asChild, ...props }: ButtonProps) {
  const Comp = asChild ? Slot : 'button';
  return <Comp className={cn(buttonVariants({ variant, size, className }))} {...props} />;
}
```

## Why `asChild` via Radix `Slot`

`<Button asChild><Link to="/">Home</Link></Button>` — renders a real `<a>` (from your Link) but inherits Button's classes. Avoids div-in-link / link-in-button structural problems.

## Token integration with Tailwind v4

Tokens defined in `@theme` (see `platform-web.md`) auto-generate the `bg-*`/`text-*`/`hover:*` utilities cva consumes. The `@theme` declarations bridge `:root` tokens into Tailwind's utility generator — the `var(...)` self-reference is intentional so dark-mode overrides on `:root` propagate to Tailwind utilities (note the kebab-case rename for the `-hover` variant):

```css
@theme {
  --color-interactive-primary: var(--color-interactive-primary);            /* bridge :root → utility */
  --color-interactive-primary-hover: var(--color-interactive-primaryHover); /* camelCase :root → kebab utility */
}
```
→ Tailwind generates `bg-interactive-primary`, `hover:bg-interactive-primary-hover` automatically.

## Forms — pair with react-hook-form + zod

shadcn's `Form` component wraps react-hook-form with Radix's `Label` and a `FormField` adapter. Use `@hookform/resolvers/zod` for schema-typed forms.

## When NOT to use shadcn

- Highly bespoke design language that doesn't map to Radix Primitives' interaction model
- Need fully framework-agnostic components (shadcn is React-only; for Vue/Solid see Park UI, Ark UI, Kobalte)
- Strict bundle-size constraints where the Radix dependency is too much

## Alternatives

- **Park UI / Ark UI** — same idea, multi-framework via Zag.js
- **Headless UI** — Tailwind Labs' own headless library; smaller surface area
- **base-ui** (MUI's new headless) — Radix-style but from MUI team
