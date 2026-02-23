# Next.js Examples

Code examples for common patterns with Vercel React Best Practices applied.

---

## Server Actions

### Basic Form with Validation

```typescript
// features/contact/actions/sendMessage.ts
'use server';

import { z } from 'zod';
import { revalidatePath } from 'next/cache';

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  email: z.string().email('Invalid email'),
  message: z.string().min(10, 'Message must be at least 10 characters'),
});

type State = {
  error?: string;
  success?: boolean;
};

export async function sendMessage(prevState: State, formData: FormData): Promise<State> {
  const result = schema.safeParse({
    name: formData.get('name'),
    email: formData.get('email'),
    message: formData.get('message'),
  });

  if (!result.success) {
    return { error: result.error.errors[0].message };
  }

  try {
    await db.message.create({ data: result.data });
    revalidatePath('/messages');
    return { success: true };
  } catch (e) {
    return { error: 'Failed to send message' };
  }
}
```

```tsx
// features/contact/ui/ContactForm.tsx
'use client';

import { useActionState } from 'react';
import { sendMessage } from '../actions/sendMessage';

export function ContactForm() {
  const [state, dispatch, isPending] = useActionState(sendMessage, {});

  if (state.success) {
    return <p>Message sent successfully!</p>;
  }

  return (
    <form action={dispatch} className="space-y-4">
      {/* Disable all inputs during submission */}
      <fieldset disabled={isPending}>
        <div>
          <label htmlFor="name">Name</label>
          <input id="name" name="name" required />
        </div>
        
        <div>
          <label htmlFor="email">Email</label>
          <input id="email" name="email" type="email" required />
        </div>
        
        <div>
          <label htmlFor="message">Message</label>
          <textarea id="message" name="message" required />
        </div>

        {state.error && (
          <p className="text-red-500">{state.error}</p>
        )}

        <button type="submit">
          {isPending ? 'Sending...' : 'Send Message'}
        </button>
      </fieldset>
    </form>
  );
}
```

### Optimistic Updates

```tsx
'use client';

import { useOptimistic } from 'react';
import { toggleLike } from '../actions/toggleLike';

export function LikeButton({ post }: { post: Post }) {
  const [optimisticLikes, addOptimistic] = useOptimistic(
    post.likes,
    (state, increment: number) => state + increment
  );

  return (
    <form
      action={async () => {
        addOptimistic(1);
        await toggleLike(post.id);
      }}
    >
      <button type="submit">❤️ {optimisticLikes}</button>
    </form>
  );
}
```

### Delete with Confirmation

```typescript
// features/post/actions/deletePost.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';

export async function deletePost(id: string) {
  await db.post.delete({ where: { id } });
  revalidatePath('/posts');
  redirect('/posts');
}
```

```tsx
'use client';

import { useTransition } from 'react';
import { toast } from 'sonner';
import { deletePost } from '../actions/deletePost';

export function DeleteButton({ postId }: { postId: string }) {
  const [isPending, startTransition] = useTransition();

  const handleDelete = () => {
    if (!confirm('Are you sure?')) return;
    
    startTransition(async () => {
      try {
        await deletePost(postId);
      } catch (e) {
        toast.error('Failed to delete post');
      }
    });
  };

  return (
    <button onClick={handleDelete} disabled={isPending}>
      {isPending ? 'Deleting...' : 'Delete'}
    </button>
  );
}
```

---

## Data Fetching

### Parallel Data Fetching (Composition Pattern)

```tsx
// app/dashboard/page.tsx — non-async parent, async children fetch in parallel
import { Suspense } from 'react';

export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>

      <Suspense fallback={<StatsSkeleton />}>
        <StatsSection />
      </Suspense>

      <Suspense fallback={<ChartSkeleton />}>
        <RevenueChart />
      </Suspense>

      <Suspense fallback={<TableSkeleton />}>
        <RecentOrdersTable />
      </Suspense>
    </div>
  );
}

// Each async SC fetches independently — no waterfall
async function StatsSection() {
  const stats = await getStats();
  return <StatsCards stats={stats} />;
}

async function RevenueChart() {
  const data = await getRevenueData();
  return <Chart data={data} />;
}

async function RecentOrdersTable() {
  const orders = await getRecentOrders();
  return <OrdersTable orders={orders} />;
}
```

Use `Promise.all()` only when all data must be available before any rendering:

```tsx
// API route or Server Action — not components
const [session, config] = await Promise.all([auth(), fetchConfig()]);
```

### Data with Caching

```typescript
// entities/user/api/getUser.ts
import { cache } from 'react';
import { LRUCache } from 'lru-cache';

// Per-request deduplication — multiple components calling getUser() share one query
export const getUser = cache(async (id: string) => {
  return db.user.findUnique({ where: { id } });
});

// Cross-request LRU cache — persists across sequential requests
const userCache = new LRUCache<string, User>({ max: 500, ttl: 5 * 60 * 1000 });

export async function getCachedUser(id: string) {
  const cached = userCache.get(id);
  if (cached) return cached;
  const user = await db.user.findUnique({ where: { id }, include: { profile: true } });
  if (user) userCache.set(id, user);
  return user;
}
```

### Non-Blocking Side Effects with after()

```typescript
// features/post/actions/createPost.ts
import { after } from 'next/server';

export async function POST(request: Request) {
  const post = await createPost(await request.json());

  // Runs after response is sent — doesn't slow down the user
  after(async () => {
    await logActivity({ action: 'post_created', postId: post.id });
    await notifySubscribers(post);
  });

  return Response.json(post, { status: 201 });
}
```

---

## Auth Patterns

> **Auth.js v5** (`next-auth@5`) uses a unified `auth()` function that replaces `getServerSession`, `getToken`, `withAuth`, and `useSession` from v4. The examples below use Auth.js v5 patterns.
>
> **Security note**: After CVE-2025-29927, do NOT rely solely on middleware for auth. Always validate auth at the route/component level. Middleware is useful for redirects but should not be the only guard.

### Auth Configuration (Auth.js v5)

```typescript
// shared/lib/auth.ts
import NextAuth from 'next-auth';
import GitHub from 'next-auth/providers/github';

export const { handlers, auth, signIn, signOut } = NextAuth({
  providers: [GitHub],
});
```

```typescript
// app/api/auth/[...nextauth]/route.ts
import { handlers } from '@/shared/lib/auth';
export const { GET, POST } = handlers;
```

### Server Component Auth Check (primary auth layer)

```tsx
// app/dashboard/page.tsx
import { redirect } from 'next/navigation';
import { auth } from '@/shared/lib/auth';

export default async function DashboardPage() {
  const session = await auth();

  if (!session) {
    redirect('/login');
  }

  return (
    <div>
      <h1>Welcome, {session.user?.name}</h1>
      {/* Dashboard content */}
    </div>
  );
}
```

### Middleware (redirects only, NOT sole auth layer)

```typescript
// middleware.ts
import { auth } from '@/shared/lib/auth';

export default auth((req) => {
  const { pathname } = req.nextUrl;

  // Redirect unauthenticated users to login (convenience redirect, not security boundary)
  if (!req.auth && pathname.startsWith('/dashboard')) {
    const loginUrl = new URL('/login', req.url);
    loginUrl.searchParams.set('callbackUrl', pathname);
    return Response.redirect(loginUrl);
  }
});

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

### Client-Side Auth Hook

```tsx
// shared/lib/useAuth.ts
'use client';

import { useSession } from 'next-auth/react';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

export function useRequireAuth() {
  const { data: session, status } = useSession();
  const router = useRouter();

  useEffect(() => {
    if (status === 'unauthenticated') {
      router.push('/login');
    }
  }, [status, router]);

  return { session, isLoading: status === 'loading' };
}
```

---

## TanStack Query (Client Components)

```tsx
// features/products/api/queryKeys.ts
export const productKeys = {
  all: ['products'] as const,                                        // invalidate everything
  lists: () => [...productKeys.all, 'list'] as const,                // all lists
  list: (filters: Filters) => [...productKeys.lists(), filters] as const, // specific list
  details: () => [...productKeys.all, 'detail'] as const,            // all details
  detail: (id: string) => [...productKeys.details(), id] as const,   // single detail
}
```

```tsx
// features/products/api/useProducts.ts
'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { productKeys } from './queryKeys';

export function useProducts(filters: Filters) {
  return useQuery({
    queryKey: productKeys.list(filters),
    queryFn: () => fetchProducts(filters),
    staleTime: 5 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: createProduct,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: productKeys.lists() });
    },
  });
}

// Usage in component
function ProductsPage() {
  const { data: products, isLoading } = useProducts(filters);
  const { mutate: create, isPending } = useCreateProduct();
  
  // ...
}
```

---

## Zustand (Client State)

```typescript
// shared/store/cartStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

interface CartStore {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;
  clearCart: () => void;
}

export const useCartStore = create<CartStore>()(
  persist(
    (set) => ({
      items: [],
      addItem: (item) => set((state) => ({ 
        items: [...state.items, item] 
      })),
      removeItem: (id) => set((state) => ({ 
        items: state.items.filter((i) => i.id !== id) 
      })),
      clearCart: () => set({ items: [] }),
    }),
    { name: 'cart-storage' }
  )
);

// Derived state selectors - subscribe only to computed values
// Components using these will only re-render when the derived value changes
export const useCartTotal = () => 
  useCartStore((state) => 
    state.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  );

export const useCartCount = () => 
  useCartStore((state) => 
    state.items.reduce((sum, item) => sum + item.quantity, 0)
  );

export const useCartEmpty = () => 
  useCartStore((state) => state.items.length === 0);
```

```tsx
// Usage example - each component subscribes only to what it needs
'use client';

import { useCartStore, useCartTotal, useCartCount } from '@/shared/store/cartStore';

// Only re-renders when total changes
function CartTotal() {
  const total = useCartTotal();
  return <span>${total.toFixed(2)}</span>;
}

// Only re-renders when count changes
function CartBadge() {
  const count = useCartCount();
  if (count === 0) return null;
  return <span className="badge">{count}</span>;
}

// Only re-renders when items array changes
function CartItems() {
  const items = useCartStore((state) => state.items);
  const removeItem = useCartStore((state) => state.removeItem);

  return (
    <ul>
      {items.map((item) => (
        <li key={item.id}>
          {item.name} - ${item.price}
          <button onClick={() => removeItem(item.id)}>Remove</button>
        </li>
      ))}
    </ul>
  );
}
```

---

## Route Handlers

### Basic CRUD Route Handler

```typescript
// app/api/products/route.ts
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { auth } from '@/shared/lib/auth';

const createSchema = z.object({
  name: z.string().min(1),
  price: z.number().positive(),
});

// GET is uncached by default in Next.js 15+
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const page = Number(searchParams.get('page') ?? '1');

  const products = await db.product.findMany({
    take: 20,
    skip: (page - 1) * 20,
  });

  return NextResponse.json(products);
}

export async function POST(request: Request) {
  const session = await auth();
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const body = await request.json();
  const result = createSchema.safeParse(body);

  if (!result.success) {
    return NextResponse.json({ error: result.error.flatten() }, { status: 400 });
  }

  const product = await db.product.create({ data: result.data });
  return NextResponse.json(product, { status: 201 });
}
```

### Dynamic Route Handler

```typescript
// app/api/products/[id]/route.ts
import { NextResponse } from 'next/server';

// params is a Promise in Next.js 15+ — must await
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const product = await db.product.findUnique({ where: { id } });

  if (!product) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  return NextResponse.json(product);
}
```

### Webhook Handler

```typescript
// app/api/webhooks/stripe/route.ts
import { headers } from 'next/headers';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function POST(request: Request) {
  const body = await request.text();
  const headersList = await headers();
  const signature = headersList.get('stripe-signature')!;

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch {
    return new Response('Invalid signature', { status: 400 });
  }

  switch (event.type) {
    case 'checkout.session.completed':
      await handleCheckoutComplete(event.data.object);
      break;
  }

  return new Response('OK', { status: 200 });
}
```
